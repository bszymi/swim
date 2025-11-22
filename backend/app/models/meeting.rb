class Meeting < ApplicationRecord
  self.table_name = "meet_standard_sets"

  has_many :meeting_standards, dependent: :destroy, foreign_key: "meet_standard_set_id"
  has_one :meet_rule, dependent: :destroy, foreign_key: "meet_standard_set_id"
  has_one_attached :pdf_document
  belongs_to :live_meeting, optional: true

  validates :name, presence: true

  accepts_nested_attributes_for :meeting_standards, allow_destroy: true
  accepts_nested_attributes_for :meet_rule

  def age_reference_date
    # Check for age_on_date rule (case insensitive)
    if age_rule_type&.downcase&.include?("age") && age_rule_type&.downcase&.include?("date") && age_rule_date.present?
      return age_rule_date
    end

    # For calendar_year age rule, use the season year if available
    year = if age_rule_type == "calendar_year" && season.present?
             season.to_i
    else
             window_end&.year || Date.today.year
    end

    Date.new(year, 12, 31)
  end
end
