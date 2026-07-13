class TrackEntry < ApplicationRecord
  belongs_to :event

  # タグ列は配列型（null: false, default: []）。フォーム未入力等でnilが渡ってもDB制約に違反しないよう空配列に正規化する。
  before_validation :normalize_tags

  # identified（識別済みフラグ）は title の有無から自動導出する。
  # 曲名が空の間は「未識別」、後から曲名を追記して保存すると自動で「識別済み」になる（機能⑩）。
  # title を唯一の判定基準にすることで、フラグとデータの不整合（曲名なしなのに識別済み等）を防ぐ。
  before_save :sync_identified

  # 情報が何もない空の楽曲を防ぐため、ジャンルと雰囲気タグは最低1つずつ必須。
  # message は各フィールド直下にそのまま出すため、属性名なしで完結する文言にする。
  validates :genre, presence: { message: "ジャンルを1つ以上入力してください" }
  validates :mood, presence: { message: "雰囲気タグを1つ以上入力してください" }

  # 体感BPMは任意入力。入力時は0以上の整数のみ許可する。
  # message は各フィールド直下にそのまま出すため、属性名なしで完結する文言にする。
  validates :bpm,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0,
              message: "0以上の整数で入力してください"
            },
            allow_nil: true

  private

  # nil を空配列に、また空文字などの無効なタグを取り除く。
  # これにより「空文字だけのタグ」を presence 検証で正しく無効と判定できる。
  def normalize_tags
    self.genre = Array(genre).reject(&:blank?)
    self.mood = Array(mood).reject(&:blank?)
  end

  # title があれば識別済み（true）、空なら未識別（false）。
  def sync_identified
    self.identified = title.present?
  end
end
