class County < ApplicationRecord
  belongs_to :region
  has_many :live_meetings, dependent: :nullify

  validates :name, presence: true
  validates :name, uniqueness: { scope: :region_id }
end
