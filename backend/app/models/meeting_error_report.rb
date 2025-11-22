class MeetingErrorReport < ApplicationRecord
  STATUSES = %w[pending resolved].freeze

  belongs_to :meeting, foreign_key: "meet_standard_set_id", class_name: "Meeting"
  belongs_to :user

  validates :description, presence: true, length: { minimum: 10, maximum: 1000 }
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }
  scope :resolved, -> { where(status: "resolved") }
  scope :recent, -> { order(created_at: :desc) }

  def pending?
    status == "pending"
  end

  def resolved?
    status == "resolved"
  end

  def mark_as_resolved!
    update!(status: "resolved")
  end
end
