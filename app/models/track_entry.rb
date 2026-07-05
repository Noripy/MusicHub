class TrackEntry < ApplicationRecord
  belongs_to :event

  # タグ列は配列型（null: false, default: []）。フォーム未入力等でnilが渡ってもDB制約に違反しないよう空配列に正規化する。
  before_validation :normalize_tags

  # 体感BPMは任意入力。入力時は0以上の整数のみ許可する。
  validates :bpm, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  private

  def normalize_tags
    self.genre = [] if genre.nil?
    self.mood = [] if mood.nil?
  end
end
