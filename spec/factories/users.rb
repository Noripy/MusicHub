FactoryBot.define do
  factory :user do
    name { "Test User" }
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "password1234" }
    password_confirmation { "password1234" }
  end
end
