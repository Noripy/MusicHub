#!/bin/bash

set -e
# エラーが発生したら即座にスクリプトを終了する設定

rm -f /rails/tmp/pids/server.pid
# サーバーの二重起動を防ぐため、前回のサーバーPIDファイルを削除

exec "$@"
# docker-compose.yml の command を実行
