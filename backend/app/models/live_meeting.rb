class LiveMeeting < ApplicationRecord
  belongs_to :region, optional: true
  belongs_to :county, optional: true
  has_many :meetings, dependent: :nullify

  validates :name, :start_date, :course_type, presence: true
  validates :course_type, inclusion: { in: %w[25 50] }
  validates :meet_number, uniqueness: true, allow_nil: true

  scope :upcoming, -> { where("start_date >= ?", Date.current).order(:start_date) }
  scope :today, -> { where(start_date: Date.current) }
  scope :this_week, -> { where(start_date: Date.current..(Date.current + 7.days)) }
  scope :by_region, ->(region_id) { where(region_id: region_id) }

  def ongoing?
    start_date <= Date.current && (end_date.nil? || end_date >= Date.current)
  end

  def course_type_display
    course_type == "25" ? "25m (Short Course)" : "50m (Long Course)"
  end
end
