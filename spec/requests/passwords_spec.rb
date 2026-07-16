require "rails_helper"

RSpec.describe "Passwords", type: :request do
  let(:user) { create(:user, email_address: "owner@example.com") }

  describe "GET /passwords/new" do
    it "200 を返す" do
      get new_password_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /passwords" do
    context "登録済みのメールアドレス" do
      it "PasswordsMailer#reset がキューイングされる" do
        expect {
          post passwords_path, params: { email_address: user.email_address }
        }.to have_enqueued_mail(PasswordsMailer, :reset)
      end

      it "new_session_path へリダイレクトされる" do
        post passwords_path, params: { email_address: user.email_address }
        expect(response).to redirect_to(new_session_path)
      end

      it "案内メッセージがフラッシュに設定される" do
        post passwords_path, params: { email_address: user.email_address }
        expect(flash[:notice]).to eq("パスワード再設定の案内を送信しました（該当のメールアドレスが登録されている場合）。")
      end
    end

    context "未登録のメールアドレス" do
      it "PasswordsMailer#reset はキューイングされない" do
        expect {
          post passwords_path, params: { email_address: "nobody@example.com" }
        }.not_to have_enqueued_mail(PasswordsMailer, :reset)
      end

      it "登録済みの場合と同じ new_session_path へリダイレクトされる" do
        post passwords_path, params: { email_address: "nobody@example.com" }
        expect(response).to redirect_to(new_session_path)
      end

      it "登録済みの場合と同じフラッシュメッセージが設定される（アドレス存在の漏洩防止）" do
        post passwords_path, params: { email_address: "nobody@example.com" }
        expect(flash[:notice]).to eq("パスワード再設定の案内を送信しました（該当のメールアドレスが登録されている場合）。")
      end
    end
  end

  describe "GET /passwords/:token/edit" do
    it "有効なトークンなら 200 を返す" do
      get edit_password_path(user.password_reset_token)
      expect(response).to have_http_status(:ok)
    end

    it "無効なトークンなら new_password_path へリダイレクトされる" do
      get edit_password_path("invalid-token")
      expect(response).to redirect_to(new_password_path)
    end

    it "無効なトークンならエラーメッセージがフラッシュに設定される" do
      get edit_password_path("invalid-token")
      expect(flash[:alert]).to eq("パスワード再設定リンクが無効か、有効期限が切れています。")
    end

    it "発行から15分を超えた期限切れトークンは new_password_path へリダイレクトされる" do
      token = user.password_reset_token
      travel 16.minutes do
        get edit_password_path(token)
        expect(response).to redirect_to(new_password_path)
      end
    end

    it "期限切れトークンならエラーメッセージがフラッシュに設定される" do
      token = user.password_reset_token
      travel 16.minutes do
        get edit_password_path(token)
        expect(flash[:alert]).to eq("パスワード再設定リンクが無効か、有効期限が切れています。")
      end
    end
  end

  describe "PUT /passwords/:token" do
    context "有効なトークンかつパスワードが一致" do
      it "パスワードが更新される" do
        put password_path(user.password_reset_token), params: { password: "new_password123", password_confirmation: "new_password123" }
        expect(user.reload.authenticate("new_password123")).to eq(user)
      end

      it "ログイン中のセッションが全て破棄される" do
        session_record = user.sessions.create!(user_agent: "test", ip_address: "127.0.0.1")
        expect {
          put password_path(user.password_reset_token), params: { password: "new_password123", password_confirmation: "new_password123" }
        }.to change(user.sessions, :count).by(-1)
        expect(Session.exists?(session_record.id)).to be false
      end

      it "new_session_path へリダイレクトされる" do
        put password_path(user.password_reset_token), params: { password: "new_password123", password_confirmation: "new_password123" }
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "パスワード確認が一致しない" do
      it "パスワードが更新されない" do
        original_digest = user.password_digest
        put password_path(user.password_reset_token), params: { password: "new_password123", password_confirmation: "mismatch" }
        expect(user.reload.password_digest).to eq(original_digest)
      end

      it "edit_password_path へリダイレクトされる" do
        token = user.password_reset_token
        put password_path(token), params: { password: "new_password123", password_confirmation: "mismatch" }
        expect(response).to redirect_to(edit_password_path(token))
      end
    end

    context "期限切れトークン" do
      it "パスワードが更新されず new_password_path へリダイレクトされる" do
        token = user.password_reset_token
        original_digest = user.password_digest

        travel 16.minutes do
          put password_path(token), params: { password: "new_password123", password_confirmation: "new_password123" }
          expect(response).to redirect_to(new_password_path)
        end

        expect(user.reload.password_digest).to eq(original_digest)
      end
    end
  end
end
