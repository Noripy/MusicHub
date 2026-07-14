require "rails_helper"

RSpec.describe "TrackEntries", type: :request do
  let(:user) { create(:user) }
  let(:event) { create(:event, user: user) }

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password123" }
  end

  describe "GET /track_entries（未識別エントリ一覧・全イベント横断）" do
    context "ログイン済み" do
      before { sign_in(user) }

      it "200 を返す" do
        get track_entries_path
        expect(response).to have_http_status(:ok)
      end

      it "自分のイベントの未識別エントリのみを新しい順に表示する" do
        other_event = create(:event, user: user, name: "Other Event")
        create(:track_entry, event: event, title: "", memo: "古いメモ", created_at: 2.days.ago)
        create(:track_entry, event: other_event, title: "", memo: "新しいメモ", created_at: 1.day.ago)
        create(:track_entry, event: event, title: "Strobe") # 識別済みは含まれない

        get track_entries_path

        expect(response.body.index("新しいメモ")).to be < response.body.index("古いメモ")
      end

      it "識別済みエントリは含まれない" do
        create(:track_entry, event: event, title: "Strobe")

        get track_entries_path

        expect(response.body).not_to include("Strobe")
      end

      it "他人のイベントの未識別エントリは含まれない" do
        others_event = create(:event)
        create(:track_entry, event: others_event, title: "", memo: "他人のメモ")

        get track_entries_path

        expect(response.body).not_to include("他人のメモ")
      end

      it "未識別のエントリがなければ空状態のメッセージを表示する" do
        get track_entries_path
        expect(response.body).to include("未識別の楽曲はありません")
      end
    end

    context "未ログイン" do
      it "new_session_path へリダイレクトされる" do
        get track_entries_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /events/:event_id/track_entries/new" do
    context "ログイン済み・自分のイベント" do
      before { sign_in(user) }

      it "200 を返す" do
        get new_event_track_entry_path(event)
        expect(response).to have_http_status(:ok)
      end
    end

    context "ログイン済み・他人のイベント" do
      before { sign_in(user) }

      it "404 を返す" do
        others_event = create(:event)
        get new_event_track_entry_path(others_event)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "未ログイン" do
      it "new_session_path へリダイレクトされる" do
        get new_event_track_entry_path(event)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /events/:event_id/track_entries" do
    let(:valid_params) do
      {
        track_entry: {
          title: "Strobe",
          genre: %w[Techno House],
          mood: %w[Dark],
          bpm: 128,
          memo: "ラスト前のアンセム"
        }
      }
    end

    context "ログイン済み・有効なパラメータ" do
      before { sign_in(user) }

      it "TrackEntry が 1 件増える" do
        expect {
          post event_track_entries_path(event), params: valid_params
        }.to change(event.track_entries, :count).by(1)
      end

      it "配列タグ・bpm・memo が保存される" do
        post event_track_entries_path(event), params: valid_params
        expect(event.track_entries.last).to have_attributes(
          genre: %w[Techno House],
          mood: %w[Dark],
          bpm: 128,
          memo: "ラスト前のアンセム"
        )
      end

      it "イベント詳細へリダイレクトされフラッシュが出る" do
        post event_track_entries_path(event), params: valid_params
        expect(response).to redirect_to(event_path(event))
        expect(flash[:notice]).to eq("楽曲を登録しました")
      end
    end

    context "ログイン済み・曲名が空欄（未識別トラック）" do
      before { sign_in(user) }

      it "ジャンルと雰囲気タグがあれば曲名なしでも登録できる" do
        expect {
          post event_track_entries_path(event),
               params: { track_entry: { title: "", genre: %w[Techno], mood: %w[Dark] } }
        }.to change(event.track_entries, :count).by(1)
      end
    end

    context "ログイン済み・ジャンルと雰囲気タグが未入力" do
      before { sign_in(user) }

      it "何も入力せず送ると登録されず 422 を返す（空の楽曲を防ぐ）" do
        expect {
          post event_track_entries_path(event), params: { track_entry: { title: "" } }
        }.not_to change(TrackEntry, :count)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "ジャンルだけでは登録できない" do
        expect {
          post event_track_entries_path(event),
               params: { track_entry: { genre: %w[Techno], mood: [] } }
        }.not_to change(TrackEntry, :count)
      end

      it "雰囲気タグだけでは登録できない" do
        expect {
          post event_track_entries_path(event),
               params: { track_entry: { genre: [], mood: %w[Dark] } }
        }.not_to change(TrackEntry, :count)
      end

      it "適切な入力を促すエラーメッセージが表示される" do
        post event_track_entries_path(event), params: { track_entry: { title: "" } }
        expect(response.body).to include("ジャンルを1つ以上入力してください")
        expect(response.body).to include("雰囲気タグを1つ以上入力してください")
      end
    end

    context "ログイン済み・bpm が不正な値" do
      before { sign_in(user) }

      it "負の値は登録されず 422 を返す" do
        expect {
          post event_track_entries_path(event),
               params: { track_entry: { bpm: -1 } }
        }.not_to change(TrackEntry, :count)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "適切な入力を促すエラーメッセージが表示される" do
        post event_track_entries_path(event), params: { track_entry: { bpm: -1 } }
        expect(response.body).to include("0以上の整数で入力してください")
      end

      it "エラー時は入力欄がエラー表示になる" do
        post event_track_entries_path(event), params: { track_entry: { bpm: -1 } }
        expect(response.body).to include("mh-input-error")
      end

      it "小数は登録されず 422 を返す" do
        expect {
          post event_track_entries_path(event),
               params: { track_entry: { bpm: "128.5" } }
        }.not_to change(TrackEntry, :count)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "ログイン済み・他人のイベント" do
      before { sign_in(user) }

      it "404 を返し登録されない" do
        others_event = create(:event)
        expect {
          post event_track_entries_path(others_event), params: valid_params
        }.not_to change(TrackEntry, :count)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "未ログイン" do
      it "new_session_path へリダイレクトされる" do
        post event_track_entries_path(event), params: valid_params
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /events/:event_id/track_entries/:id/edit" do
    let!(:track_entry) { create(:track_entry, event: event, title: "") }

    context "ログイン済み・自分のイベント" do
      before { sign_in(user) }

      it "200 を返す" do
        get edit_event_track_entry_path(event, track_entry)
        expect(response).to have_http_status(:ok)
      end
    end

    context "ログイン済み・他人のイベント" do
      before { sign_in(user) }

      it "404 を返す" do
        others_event = create(:event)
        others_track_entry = create(:track_entry, event: others_event)
        get edit_event_track_entry_path(others_event, others_track_entry)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "未ログイン" do
      it "new_session_path へリダイレクトされる" do
        get edit_event_track_entry_path(event, track_entry)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PATCH /events/:event_id/track_entries/:id" do
    let!(:track_entry) { create(:track_entry, event: event, title: "") }

    context "ログイン済み・曲名を追記して更新（機能⑩の核）" do
      before { sign_in(user) }

      it "identified が true に切り替わる" do
        patch event_track_entry_path(event, track_entry), params: { track_entry: { title: "Strobe" } }
        expect(track_entry.reload).to have_attributes(title: "Strobe", identified: true)
      end

      it "イベント詳細へリダイレクトされフラッシュが出る" do
        patch event_track_entry_path(event, track_entry), params: { track_entry: { title: "Strobe" } }
        expect(response).to redirect_to(event_path(event))
        expect(flash[:notice]).to eq("楽曲を更新しました")
      end
    end

    context "ログイン済み・不正な値で更新" do
      before { sign_in(user) }

      it "更新されず 422 を返す" do
        patch event_track_entry_path(event, track_entry), params: { track_entry: { bpm: -1 } }
        expect(track_entry.reload.bpm).to be_nil
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "適切な入力を促すエラーメッセージが表示される" do
        patch event_track_entry_path(event, track_entry), params: { track_entry: { bpm: -1 } }
        expect(response.body).to include("0以上の整数で入力してください")
      end
    end

    context "ログイン済み・他人のイベント" do
      before { sign_in(user) }

      it "404 を返し更新されない" do
        others_event = create(:event)
        others_track_entry = create(:track_entry, event: others_event, title: "")
        patch event_track_entry_path(others_event, others_track_entry),
              params: { track_entry: { title: "Strobe" } }
        expect(response).to have_http_status(:not_found)
        expect(others_track_entry.reload.title).to eq("")
      end
    end

    context "未ログイン" do
      it "new_session_path へリダイレクトされる" do
        patch event_track_entry_path(event, track_entry), params: { track_entry: { title: "Strobe" } }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /events/:event_id/track_entries/:id" do
    let!(:track_entry) { create(:track_entry, event: event) }

    context "ログイン済み・自分のイベントの楽曲" do
      before { sign_in(user) }

      it "TrackEntry が 1 件減る" do
        expect {
          delete event_track_entry_path(event, track_entry)
        }.to change(TrackEntry, :count).by(-1)
      end

      it "イベント詳細へリダイレクトされる" do
        delete event_track_entry_path(event, track_entry)
        expect(response).to redirect_to(event_path(event))
      end

      it "削除成功のフラッシュメッセージが設定される" do
        delete event_track_entry_path(event, track_entry)
        expect(flash[:notice]).to eq("楽曲を削除しました")
      end
    end

    context "ログイン済み・他人のイベントの楽曲" do
      let!(:other_track_entry) { create(:track_entry, event: create(:event)) }

      before { sign_in(user) }

      it "404 を返す" do
        delete event_track_entry_path(other_track_entry.event, other_track_entry)
        expect(response).to have_http_status(:not_found)
      end

      it "TrackEntry は削除されない" do
        expect {
          delete event_track_entry_path(other_track_entry.event, other_track_entry)
        }.not_to change(TrackEntry, :count)
      end
    end

    context "未ログイン" do
      it "new_session_path へリダイレクトされる" do
        delete event_track_entry_path(event, track_entry)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
