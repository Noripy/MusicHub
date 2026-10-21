class Session < ApplicationRecord
  # ログインから一定期間で失効させる。Cookie を盗まれても使える期間を限定する。
  TTL = 2.weeks

  belongs_to :user

  scope :active, -> { where(created_at: TTL.ago..) }
end
