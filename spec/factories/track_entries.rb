FactoryBot.define do
  factory :track_entry do
    event
    title { "テスト曲" }
    genre { %w[Techno] }
    mood { %w[Dark] }
    bpm { nil }
    memo { nil }
    # identified は title から自動導出されるため明示しない（モデルの before_save が決定する）
  end
end
