# syntax=docker/dockerfile:1
# check=error=true
#
# MusicHub - 1ファイルで dev / prod を賄うマルチステージ Dockerfile
#
#   development : ローカル開発（OrbStack + compose.yaml）で使う
#   production  : Render へデプロイする本番イメージ（slim・非root）
#
# ビルド例:
#   docker build --target development -t musichub:dev .
#   docker build --target production  -t musichub:prod .
#
# Ruby バージョンは ARG で差し替え可能（READMEの 4.0.4 を既定値に）。
# ★ ruby:<version>-slim タグが Docker Hub に存在するか一度だけ確認してください。
ARG RUBY_VERSION=4.0.4


###############################################################################
# 1) base — dev / prod が共通で継承する「実行時の土台」
#    ここには “動かすのに必要な” ライブラリだけを入れる（ビルド用は入れない）
###############################################################################
FROM docker.io/library/ruby:${RUBY_VERSION}-slim AS base
WORKDIR /rails

# 実行時に必要な OS パッケージ
#   libpq5       : pg gem（PostgreSQL / Neon への接続）
#   libsqlite3-0 : sqlite3 gem
#   libvips      : Active Storage の画像処理
#   libyaml-0-2  : Psych（RubyのYAML）
#   libjemalloc2 : メモリ断片化を抑える（Renderの限られたRAMで効く）
#   curl         : ヘルスチェック等
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl libpq5 libsqlite3-0 libvips libyaml-0-2 libjemalloc2 && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Bundler の置き場所を /rails の外に固定する。
# → compose で `.:/rails` をバインドマウントしても gem が消えない（重要）
ENV BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_APP_CONFIG="/usr/local/bundle"


###############################################################################
# 2) gems-build — ネイティブ拡張をコンパイルする中間層
#    dev / prod の両方がここを親にするので、ビルド用パッケージは1回だけ入る
###############################################################################
FROM base AS gems-build
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential git pkg-config libpq-dev libsqlite3-dev libyaml-dev && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Gemfile だけ先にコピー → これがレイヤキャッシュの肝。
# アプリのコードを変えても Gemfile が変わらなければ bundle install は再実行されない。
COPY Gemfile Gemfile.lock ./


###############################################################################
# 3) development — ローカル開発用の最終ターゲット
#    dev / test を含む全 gem を入れる
###############################################################################
FROM gems-build AS development
ENV RAILS_ENV="development"

RUN bundle install && \
    rm -rf "${BUNDLE_PATH}"/ruby/*/cache

# 単体でも動くようコードを入れておく（compose ではバインドマウントが上書きする）
COPY . .
RUN chmod +x bin/* 2>/dev/null || true

EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]


###############################################################################
# 4) prod-build — 本番用に gem を絞り、asset を precompile する中間層
###############################################################################
FROM gems-build AS prod-build
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_WITHOUT="development:test"

RUN bundle install && \
    rm -rf "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .

# bootsnap 事前コンパイルで本番の起動を速くする
RUN bundle exec bootsnap precompile app/ lib/

# asset precompile。本物の SECRET_KEY_BASE は実行時に渡すので、
# ここではダミーフラグでビルドだけ通す（tailwindcss:build もここで走る）
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile


###############################################################################
# 5) production — Render へ載せる最終イメージ
#    base からやり直し、必要な成果物だけを COPY して軽量・安全に保つ
###############################################################################
FROM base AS production
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_WITHOUT="development:test"

# 絞った gem と、precompile済みアプリだけを持ってくる
COPY --from=prod-build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=prod-build /rails /rails

# 非rootユーザーで実行（万一の侵害時の被害を最小化）
RUN mkdir -p db log storage tmp && \
    groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Thruster(Rails 8 同梱) 経由で Puma を起動。Render が渡す PORT を Thruster が listen。
# thruster gem が無い場合は CMD ["./bin/rails", "server"] にフォールバック。
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
