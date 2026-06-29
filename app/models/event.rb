class Event < ApplicationRecord
  belongs_to :user
  has_many :track_entries, dependent: :destroy

  validates :name, presence: true
end
