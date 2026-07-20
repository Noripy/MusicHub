# credentials の復号には master key が要る。Docker の本番ビルド時（assets:precompile）は
# セキュリティ上 master key を持たせていないため、ここで存在チェックして無ければ何もしない
# （実行時に master key があるコンテナで改めてこの初期化子が走る）。
master_key_present = ENV["RAILS_MASTER_KEY"].present? || Rails.root.join("config/master.key").exist?

Resend.api_key = Rails.application.credentials.dig(:resend, :api_key) if master_key_present
