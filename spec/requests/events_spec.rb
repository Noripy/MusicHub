require "rails_helper"

RSpec.describe "Events", type: :request do
  let(:user) { create(:user) }

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password123" }
  end

  describe "GET /events/new" do
    context "ログイン済み" do
      before { sign_in(user) }

      it "200 を返す" do
        get new_event_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "未ログイン" do
      it "new_session_path へリダイレクトされる" do
        get new_event_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /events" do
    let(:valid_params) do
      {
        event: {
          name: "テストイベント",
          held_on: "2026-07-01 22:00:00",
          venue: "渋谷クラブ",
          dj_name: "DJ Test"
        }
      }
    end

    context "ログイン済み・有効なパラメータ" do
      before { sign_in(user) }

      it "Event が 1 件増える" do
        expect {
          post events_path, params: valid_params
        }.to change(Event, :count).by(1)
      end

      it "events_path へリダイレクトされる" do
        post events_path, params: valid_params
        expect(response).to redirect_to(events_path)
      end

      it "登録成功のフラッシュメッセージが設定される" do
        post events_path, params: valid_params
        expect(flash[:notice]).to eq("イベントを登録しました")
      end

      it "ログイン中のユーザーに紐づく" do
        post events_path, params: valid_params
        expect(Event.last.user).to eq(user)
      end
    end

    context "ログイン済み・name が空" do
      before { sign_in(user) }

      it "Event が増えない" do
        expect {
          post events_path, params: { event: valid_params[:event].merge(name: "") }
        }.not_to change(Event, :count)
      end

      it "422 を返す" do
        post events_path, params: { event: valid_params[:event].merge(name: "") }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "未ログイン" do
      it "new_session_path へリダイレクトされる" do
        post events_path, params: valid_params
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
