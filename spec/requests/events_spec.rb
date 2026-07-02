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

  describe "GET /events/:id" do
    let(:event) { create(:event, user: user) }

    context "ログイン済み" do
      before { sign_in(user) }

      it "200 を返す" do
        get event_path(event)
        expect(response).to have_http_status(:ok)
      end

      it "識別済みトラックのタイトルが表示される" do
        create(:track_entry, event: event, title: "Identified Track")
        get event_path(event)
        expect(response.body).to include("Identified Track")
      end

      it "track_entries が時系列（created_at: asc）で並んでいる" do
        create(:track_entry, event: event, title: "最初の曲", created_at: 1.hour.ago)
        create(:track_entry, event: event, title: "次の曲",  created_at: 30.minutes.ago)
        get event_path(event)
        expect(response.body.index("最初の曲")).to be < response.body.index("次の曲")
      end

      it "title が nil のトラックは「未識別」と表示される" do
        create(:track_entry, event: event, title: nil)
        get event_path(event)
        expect(response.body).to include("未識別")
      end
    end

    context "ログイン済み・他のユーザーのイベント" do
      let(:other_user)  { create(:user) }
      let(:other_event) { create(:event, user: other_user) }

      before { sign_in(user) }

      it "404 を返す" do
        get event_path(other_event)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "未ログイン" do
      it "new_session_path へリダイレクトされる" do
        get event_path(event)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /events/:id/edit" do
    let(:event) { create(:event, user: user) }

    context "ログイン済み" do
      before { sign_in(user) }

      it "200 を返す" do
        get edit_event_path(event)
        expect(response).to have_http_status(:ok)
      end

      it "既存の値がフォームに表示される" do
        get edit_event_path(event)
        expect(response.body).to include(event.name)
      end
    end

    context "ログイン済み・他のユーザーのイベント" do
      let(:other_user)  { create(:user) }
      let(:other_event) { create(:event, user: other_user) }

      before { sign_in(user) }

      it "404 を返す" do
        get edit_event_path(other_event)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "未ログイン" do
      it "new_session_path へリダイレクトされる" do
        get edit_event_path(event)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PATCH /events/:id" do
    let(:event) { create(:event, user: user) }
    let(:update_params) do
      {
        event: {
          name: "更新後イベント",
          held_on: "2026-08-01 23:00:00",
          venue: "新宿クラブ",
          dj_name: "DJ Updated"
        }
      }
    end

    context "ログイン済み・有効なパラメータ" do
      before { sign_in(user) }

      it "name が更新される" do
        patch event_path(event), params: update_params
        expect(event.reload.name).to eq("更新後イベント")
      end

      it "venue が更新される" do
        patch event_path(event), params: update_params
        expect(event.reload.venue).to eq("新宿クラブ")
      end

      it "dj_name が更新される" do
        patch event_path(event), params: update_params
        expect(event.reload.dj_name).to eq("DJ Updated")
      end

      it "event_path へリダイレクトされる" do
        patch event_path(event), params: update_params
        expect(response).to redirect_to(event_path(event))
      end

      it "更新成功のフラッシュメッセージが設定される" do
        patch event_path(event), params: update_params
        expect(flash[:notice]).to eq("イベントを更新しました")
      end
    end

    context "ログイン済み・name が空" do
      before { sign_in(user) }

      it "更新されない" do
        patch event_path(event), params: { event: update_params[:event].merge(name: "") }
        expect(event.reload.name).to eq("テストイベント")
      end

      it "422 を返す" do
        patch event_path(event), params: { event: update_params[:event].merge(name: "") }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "ログイン済み・他のユーザーのイベント" do
      let(:other_user)  { create(:user) }
      let(:other_event) { create(:event, user: other_user) }

      before { sign_in(user) }

      it "404 を返す" do
        patch event_path(other_event), params: update_params
        expect(response).to have_http_status(:not_found)
      end
    end

    context "未ログイン" do
      it "new_session_path へリダイレクトされる" do
        patch event_path(event), params: update_params
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
