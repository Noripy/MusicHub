require "rails_helper"

RSpec.describe User, type: :model do
  describe "バリデーション" do
    it "有効な属性で保存できる" do
      expect(build(:user)).to be_valid
    end

    describe "email_address" do
      it "空のとき無効" do
        user = build(:user, email_address: "")
        expect(user).not_to be_valid
        expect(user.errors[:email_address]).to be_present
      end

      it "重複するとき無効" do
        create(:user, email_address: "taken@example.com")
        user = build(:user, email_address: "taken@example.com")
        expect(user).not_to be_valid
        expect(user.errors[:email_address]).to be_present
      end

      it "@がない形式は無効" do
        expect(build(:user, email_address: "invalid-email")).not_to be_valid
      end

      it "ドメインがない形式は無効" do
        expect(build(:user, email_address: "user@")).not_to be_valid
      end
    end
  end

  describe "normalizes" do
    it "前後の空白を除去して保存する" do
      user = create(:user, email_address: "  user@example.com  ")
      expect(user.email_address).to eq("user@example.com")
    end

    it "大文字を小文字に変換して保存する" do
      user = create(:user, email_address: "User@Example.COM")
      expect(user.email_address).to eq("user@example.com")
    end
  end

  describe "has_secure_password" do
    it "passwordがnilのとき無効" do
      expect(build(:user, password: nil)).not_to be_valid
    end

    it "password_confirmationが一致しないとき無効" do
      expect(build(:user, password_confirmation: "wrong_password")).not_to be_valid
    end

    it "正しいパスワードでauthenticateがuserを返す" do
      user = create(:user, password: "correct_password", password_confirmation: "correct_password")
      expect(user.authenticate("correct_password")).to eq(user)
    end

    it "間違ったパスワードでauthenticateがfalseを返す" do
      user = create(:user, password: "correct_password", password_confirmation: "correct_password")
      expect(user.authenticate("wrong_password")).to be(false)
    end

    it "password_digestが平文ではない" do
      user = create(:user, password: "password123")
      expect(user.password_digest).not_to eq("password123")
    end
  end
end
