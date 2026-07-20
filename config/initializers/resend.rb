# credentials の復号には master key が要る。Docker の本番ビルド時（assets:precompile）は
# セキュリティ上 master key を持たせていないため、ここで存在チェックして無ければ何もしない
# （実行時に master key があるコンテナで改めてこの初期化子が走る）。
master_key_present = ENV["RAILS_MASTER_KEY"].present? || Rails.root.join("config/master.key").exist?

if master_key_present
  # app/ 配下のクラス（ResendSmtpSettings）参照は、オートロードが確定する
  # to_prepare フック内で行う（この時点ではまだ NameError になる）。
  Rails.application.config.to_prepare do
    Resend.api_key = Rails.application.credentials.dig(:resend, :api_key)

    if Rails.env.production?
      Rails.application.config.action_mailer.smtp_settings = ResendSmtpSettings.build
    end
  end
end
