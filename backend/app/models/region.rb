class Region < ApplicationRecord
  has_many :counties, dependent: :destroy
  has_many :live_meetings, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true
end
