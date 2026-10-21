class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :track_entries, through: :events

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true,
                            uniqueness: { case_sensitive: false },
                            format: { with: URI::MailTo::EMAIL_REGEXP }
  # 総当たり対策。上限 72 は bcrypt が扱えるバイト数（has_secure_password 側でも検証される）。
  # allow_nil で、パスワードを変更しない更新（名前の変更など）では検証しない。
  validates :password, length: { minimum: 12 }, allow_nil: true
end
