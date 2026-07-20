require "rails_helper"

RSpec.describe ResendSmtpSettings do
  describe ".build" do
    context "credentialsにresend.api_keyが設定されている場合" do
      before do
        allow(Rails.application.credentials).to receive(:dig)
          .with(:resend, :api_key).and_return("re_test_dummy_key")
      end

      it "ResendのSMTPリレー向け設定ハッシュを返すこと" do
        expect(described_class.build).to eq(
          address: "smtp.resend.com",
          port: 587,
          user_name: "resend",
          password: "re_test_dummy_key",
          authentication: :plain,
          enable_starttls_auto: true
        )
      end
    end

    context "credentialsにresend.api_keyが設定されていない場合" do
      before do
        allow(Rails.application.credentials).to receive(:dig)
          .with(:resend, :api_key).and_return(nil)
      end

      it "APIキー未設定を示すエラーを発生させること" do
        expect { described_class.build }.to raise_error(/resend.api_key/)
      end
    end
  end
end
