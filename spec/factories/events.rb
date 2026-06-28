FactoryBot.define do
  factory :event do
    user
    name { "テストイベント" }
    held_on { Time.current }
    venue { "渋谷クラブ" }
    dj_name { "DJ Test" }
  end
end
