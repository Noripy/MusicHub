require "rails_helper"

RSpec.describe TrackEntry, type: :model do
  describe "バリデーション" do
    it "有効な属性で保存できる" do
      expect(build(:track_entry)).to be_valid
    end

    describe "title（曲名）" do
      it "空欄でも有効（未識別トラック）" do
        expect(build(:track_entry, title: "")).to be_valid
      end

      it "nilでも有効（未識別トラック）" do
        expect(build(:track_entry, title: nil)).to be_valid
      end
    end

    describe "bpm（体感BPM）" do
      it "nilでも有効" do
        expect(build(:track_entry, bpm: nil)).to be_valid
      end

      it "0以上の整数なら有効" do
        expect(build(:track_entry, bpm: 128)).to be_valid
      end

      it "負の値のとき無効" do
        track = build(:track_entry, bpm: -1)
        expect(track).not_to be_valid
        expect(track.errors[:bpm]).to be_present
      end
    end
  end

  describe "タグ（配列型）" do
    it "genre は複数のタグを保持できる" do
      track = create(:track_entry, genre: %w[Techno House])
      expect(track.reload.genre).to eq(%w[Techno House])
    end

    it "mood は複数のタグを保持できる" do
      track = create(:track_entry, mood: %w[Dark Euphoric])
      expect(track.reload.mood).to eq(%w[Dark Euphoric])
    end

    it "genre のデフォルトは空配列" do
      track = create(:track_entry, genre: nil)
      expect(track.reload.genre).to eq([])
    end

    it "mood のデフォルトは空配列" do
      track = create(:track_entry, mood: nil)
      expect(track.reload.mood).to eq([])
    end
  end

  describe "identified（識別済みフラグ）" do
    it "デフォルトは false" do
      track = create(:track_entry)
      expect(track.reload.identified).to be(false)
    end

    it "true に設定できる" do
      track = create(:track_entry, identified: true)
      expect(track.reload.identified).to be(true)
    end
  end

  describe "アソシエーション" do
    it "event に属する" do
      event = create(:event)
      track = create(:track_entry, event: event)
      expect(track.event).to eq(event)
    end

    it "event がないとき無効" do
      track = build(:track_entry, event: nil)
      expect(track).not_to be_valid
      expect(track.errors[:event]).to be_present
    end

    it "event を削除すると track_entry も削除される" do
      event = create(:event)
      create(:track_entry, event: event)
      expect { event.destroy }.to change(described_class, :count).by(-1)
    end
  end
end
