require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user) }

  describe "GET /session/new" do
    it "未ログインでも 200 を返す" do
      get new_session_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /session" do
    context "正しい認証情報" do
      it "Session が 1 件増える" do
        expect {
          post session_path, params: { email_address: user.email_address, password: "password123" }
        }.to change(Session, :count).by(1)
      end

      it "root_path へリダイレクトされる" do
        post session_path, params: { email_address: user.email_address, password: "password123" }
        expect(response).to redirect_to(root_path)
      end

      it "ログイン成功のフラッシュメッセージが設定される" do
        post session_path, params: { email_address: user.email_address, password: "password123" }
        expect(flash[:notice]).to eq("ログインしました")
      end
    end

    context "誤ったパスワード" do
      it "Session が増えない" do
        expect {
          post session_path, params: { email_address: user.email_address, password: "wrong_password" }
        }.not_to change(Session, :count)
      end

      it "new_session_path へリダイレクトされる" do
        post session_path, params: { email_address: user.email_address, password: "wrong_password" }
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "存在しないメールアドレス" do
      it "Session が増えない" do
        expect {
          post session_path, params: { email_address: "nobody@example.com", password: "password123" }
        }.not_to change(Session, :count)
      end
    end
  end

  describe "DELETE /session" do
    before do
      post session_path, params: { email_address: user.email_address, password: "password123" }
    end

    it "Session が 1 件減る" do
      expect {
        delete session_path
      }.to change(Session, :count).by(-1)
    end

    it "root_path へ 303 リダイレクトされる" do
      delete session_path
      expect(response).to redirect_to(root_path)
      expect(response).to have_http_status(:see_other)
    end

    it "ログアウト成功のフラッシュメッセージが設定される" do
      delete session_path
      expect(flash[:notice]).to eq("ログアウトしました")
    end

    it "ログアウト後に :session_id cookie が削除される" do
      delete session_path
      expect(cookies[:session_id]).to be_blank
    end
  end

  describe "認証が必要なページへのアクセス制御" do
    context "未ログイン" do
      # root_path (PagesController) は allow_unauthenticated_access で公開済み。
      # require_authentication の動作は、認証必須アクション (sessions#destroy) で確認する。
      it "認証必須アクションへのアクセスは new_session_path へリダイレクトされる" do
        delete session_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "return_to によるリダイレクト" do
    it "ログイン前にアクセスしたURLへリダイレクトされる" do
      get root_path
      post session_path, params: { email_address: user.email_address, password: "password123" }
      expect(response).to redirect_to(root_url)
    end
  end
end
