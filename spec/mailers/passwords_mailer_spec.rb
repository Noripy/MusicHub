require "rails_helper"

RSpec.describe PasswordsMailer, type: :mailer do
  describe "#reset" do
    let(:user) { create(:user, email_address: "reset-target@example.com") }
    let(:mail) { described_class.reset(user) }

    it "宛先がユーザーのメールアドレスであること" do
      expect(mail.to).to eq([ "reset-target@example.com" ])
    end

    it "デフォルトのfromアドレスから送信されること" do
      expect(mail.from).to eq([ "no-reply@musichub.example" ])
    end

    it "件名がパスワード再設定であること" do
      expect(mail.subject).to eq("Reset your password")
    end

    it "本文にパスワード再設定用のトークン付きURLが含まれ、正しいユーザーに解決できること" do
      url = mail.body.encoded[%r{http://\S+/passwords/(\S+)/edit}]
      expect(url).to be_present

      token = url[%r{/passwords/(\S+)/edit}, 1]
      expect(User.find_by_password_reset_token!(token)).to eq(user)
    end
  end
end
