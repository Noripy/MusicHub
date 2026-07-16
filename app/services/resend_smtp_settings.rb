class ResendSmtpSettings
  ADDRESS = "smtp.resend.com".freeze
  PORT = 587
  USER_NAME = "resend".freeze

  def self.build
    api_key = Rails.application.credentials.dig(:resend, :api_key)
    raise "credentials に resend.api_key が設定されていません（bin/rails credentials:edit で追加してください）" if api_key.blank?

    {
      address: ADDRESS,
      port: PORT,
      user_name: USER_NAME,
      password: api_key,
      authentication: :plain,
      enable_starttls_auto: true
    }
  end
end
