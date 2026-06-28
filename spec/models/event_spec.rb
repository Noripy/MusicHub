require "rails_helper"

RSpec.describe Event, type: :model do
  describe "バリデーション" do
    it "有効な属性で保存できる" do
      expect(build(:event)).to be_valid
    end

    describe "name" do
      it "空のとき無効" do
        event = build(:event, name: "")
        expect(event).not_to be_valid
        expect(event.errors[:name]).to be_present
      end

      it "nilのとき無効" do
        event = build(:event, name: nil)
        expect(event).not_to be_valid
        expect(event.errors[:name]).to be_present
      end
    end

    describe "user_id" do
      it "userがないとき無効" do
        event = build(:event, user: nil)
        expect(event).not_to be_valid
        expect(event.errors[:user]).to be_present
      end
    end
  end

  describe "アソシエーション" do
    it "userに属する" do
      user = create(:user)
      event = create(:event, user: user)
      expect(event.user).to eq(user)
    end

    it "userを削除するとeventも削除される" do
      user = create(:user)
      create(:event, user: user)
      expect { user.destroy }.to change(described_class, :count).by(-1)
    end
  end

  describe "任意フィールド" do
    it "held_on なしでも保存できる" do
      expect(build(:event, held_on: nil)).to be_valid
    end

    it "venue なしでも保存できる" do
      expect(build(:event, venue: nil)).to be_valid
    end

    it "dj_name なしでも保存できる" do
      expect(build(:event, dj_name: nil)).to be_valid
    end
  end
end
