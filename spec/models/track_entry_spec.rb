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

      it "小数のとき無効" do
        track = build(:track_entry, bpm: 128.5)
        expect(track).not_to be_valid
        expect(track.errors[:bpm]).to be_present
      end

      it "数値でない文字列のとき無効" do
        track = build(:track_entry, bpm: "abc")
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

    it "genre に nil を渡すと空配列に正規化される" do
      track = build(:track_entry, genre: nil)
      track.valid?
      expect(track.genre).to eq([])
    end

    it "mood に nil を渡すと空配列に正規化される" do
      track = build(:track_entry, mood: nil)
      track.valid?
      expect(track.mood).to eq([])
    end
  end

  describe "タグの必須要件（空の楽曲を防ぐ）" do
    it "genre と mood の両方があれば有効" do
      expect(build(:track_entry, genre: %w[Techno], mood: %w[Dark])).to be_valid
    end

    it "genre が空だと無効" do
      track = build(:track_entry, genre: [], mood: %w[Dark])
      expect(track).not_to be_valid
      expect(track.errors[:genre]).to be_present
    end

    it "mood が空だと無効" do
      track = build(:track_entry, genre: %w[Techno], mood: [])
      expect(track).not_to be_valid
      expect(track.errors[:mood]).to be_present
    end

    it "両方空だと無効（曲名だけでは登録できない）" do
      track = build(:track_entry, title: "Strobe", genre: [], mood: [])
      expect(track).not_to be_valid
      expect(track.errors.attribute_names).to include(:genre, :mood)
    end
  end

  describe "identified（識別済みフラグ・title から自動導出）" do
    it "title が空なら保存時に false になる（未識別）" do
      track = create(:track_entry, title: "")
      expect(track.reload.identified).to be(false)
    end

    it "title があれば保存時に自動で true になる（識別済み）" do
      track = create(:track_entry, title: "Strobe")
      expect(track.reload.identified).to be(true)
    end

    it "未識別で作成後に title を追記して更新すると true になる（機能⑩の核）" do
      track = create(:track_entry, title: "")
      expect(track.reload.identified).to be(false)

      track.update!(title: "Strobe")
      expect(track.reload.identified).to be(true)
    end

    it "title を空に戻すと false に戻る（未識別へ差し戻し）" do
      track = create(:track_entry, title: "Strobe")
      track.update!(title: "")
      expect(track.reload.identified).to be(false)
    end

    it "identified を手動で true にしても title が空なら false になる（title が唯一の判定基準）" do
      track = create(:track_entry, title: "", identified: true)
      expect(track.reload.identified).to be(false)
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
