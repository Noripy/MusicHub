FactoryBot.define do
  factory :track_entry do
    event
    title { "テスト曲" }
    genre { %w[Techno] }
    mood { [] }
    bpm { nil }
    memo { nil }
    identified { false }
  end
end
