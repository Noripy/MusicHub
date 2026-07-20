require "rails_helper"

RSpec.describe "認証フロー", type: :system do
  let(:user) { create(:user, email_address: "e2e@example.com", password: "password123", password_confirmation: "password123") }

  def sign_in_via_form(email:, password:)
    visit new_session_path
    fill_in "メールアドレス", with: email
    fill_in "パスワード", with: password
    click_button "ログイン"
  end

  describe "サインアップ" do
    it "新規登録すると自動的にログインしてホームへ遷移する" do
      visit new_registration_path
      fill_in "ユーザー名（任意）", with: "のりぴー"
      fill_in "メールアドレス", with: "newuser@example.com"
      fill_in "パスワード", with: "password123"
      fill_in "パスワード（確認）", with: "password123"
      click_button "登録する"

      expect(page).to have_current_path(events_path)
      expect(page).to have_content("イベント")
    end
  end

  describe "ログイン" do
    it "正しい認証情報でログインするとホーム（イベント一覧）へ遷移する" do
      sign_in_via_form(email: user.email_address, password: "password123")

      expect(page).to have_current_path(events_path)
    end

    it "誤ったパスワードだとログイン画面に留まりエラーメッセージが表示される" do
      sign_in_via_form(email: user.email_address, password: "wrong_password")

      expect(page).to have_current_path(new_session_path)
      expect(page).to have_content("メールアドレスまたはパスワードが正しくありません")
    end
  end

  describe "ログイン必須ページへのアクセス制御" do
    it "未ログインで /events にアクセスするとログイン画面へリダイレクトされる" do
      visit events_path

      expect(page).to have_current_path(new_session_path)
    end

    it "未ログインで狙ったページにアクセス→ログイン後、元のページへ戻される（return_to）" do
      visit events_path
      expect(page).to have_current_path(new_session_path)

      fill_in "メールアドレス", with: user.email_address
      fill_in "パスワード", with: "password123"
      click_button "ログイン"

      expect(page).to have_current_path(events_path)
    end
  end

  describe "ログアウト" do
    before { sign_in_via_form(email: user.email_address, password: "password123") }

    it "ログアウトするとホームへ戻りログアウト完了メッセージが表示される" do
      click_button "ログアウト"

      expect(page).to have_current_path(root_path)
      expect(page).to have_content("ログアウトしました")
    end

    it "ログアウト後はセッションCookieが失効し、ログイン必須ページで再度ログインを求められる" do
      click_button "ログアウト"

      visit events_path

      expect(page).to have_current_path(new_session_path)
    end
  end

  describe "MVPの主要導線（イベント記録〜楽曲エントリ登録）" do
    before { sign_in_via_form(email: user.email_address, password: "password123") }

    it "ログイン後にイベントと未識別の楽曲エントリを記録できる" do
      visit events_path
      click_link "＋ イベントを記録する"

      fill_in "イベント名", with: "WARP NIGHT"
      fill_in "会場", with: "渋谷 clubasia"
      click_button "登録する"

      expect(page).to have_content("WARP NIGHT")

      click_link "WARP NIGHT"
      click_link "＋ 楽曲を追加", match: :first
      click_button "楽曲を登録"

      expect(page).to have_content("WARP NIGHT")
    end
  end
end
