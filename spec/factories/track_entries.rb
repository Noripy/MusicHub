FactoryBot.define do
  factory :track_entry do
    event
    title { "テスト曲" }
    genre { "Techno" }
    mood { nil }
    bpm { nil }
    memo { nil }
  end
end
