require "rails_helper"

RSpec.describe "Registrations", type: :request do
  describe "GET /registration/new" do
    it "200 を返す" do
      get new_registration_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /registration" do
    let(:valid_params) do
      {
        user: {
          name: "テストユーザー",
          email_address: "new@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    context "有効なパラメータ（name あり）" do
      it "ユーザーが1件作成される" do
        expect { post registration_path, params: valid_params }.to change(User, :count).by(1)
      end

      it "セッションが開始される（自動ログイン）" do
        expect { post registration_path, params: valid_params }.to change(Session, :count).by(1)
      end

      it "root_path へリダイレクトされる" do
        post registration_path, params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end

    context "有効なパラメータ（name なし — 任意項目）" do
      let(:params_without_name) do
        {
          user: {
            email_address: "noname@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end

      it "name なしでユーザーが作成される" do
        expect { post registration_path, params: params_without_name }.to change(User, :count).by(1)
      end

      it "セッションが開始される（自動ログイン）" do
        expect { post registration_path, params: params_without_name }.to change(Session, :count).by(1)
      end
    end

    context "メールアドレスが空" do
      it "ユーザーが作成されない" do
        expect {
          post registration_path, params: { user: valid_params[:user].merge(email_address: "") }
        }.not_to change(User, :count)
      end

      it "422 を返す" do
        post registration_path, params: { user: valid_params[:user].merge(email_address: "") }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "メールアドレスのフォーマットが不正" do
      it "ユーザーが作成されない" do
        expect {
          post registration_path, params: { user: valid_params[:user].merge(email_address: "invalid-email") }
        }.not_to change(User, :count)
      end

      it "422 を返す" do
        post registration_path, params: { user: valid_params[:user].merge(email_address: "invalid-email") }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "メールアドレスが重複" do
      before { create(:user, email_address: "taken@example.com") }

      it "ユーザーが作成されない" do
        expect {
          post registration_path, params: { user: valid_params[:user].merge(email_address: "taken@example.com") }
        }.not_to change(User, :count)
      end

      it "422 を返す" do
        post registration_path, params: { user: valid_params[:user].merge(email_address: "taken@example.com") }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "パスワードが空" do
      it "ユーザーが作成されない" do
        expect {
          post registration_path, params: { user: valid_params[:user].merge(password: "", password_confirmation: "") }
        }.not_to change(User, :count)
      end

      it "422 を返す" do
        post registration_path, params: { user: valid_params[:user].merge(password: "", password_confirmation: "") }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "パスワード確認が一致しない" do
      it "ユーザーが作成されない" do
        expect {
          post registration_path, params: { user: valid_params[:user].merge(password_confirmation: "mismatch") }
        }.not_to change(User, :count)
      end

      it "422 を返す" do
        post registration_path, params: { user: valid_params[:user].merge(password_confirmation: "mismatch") }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
