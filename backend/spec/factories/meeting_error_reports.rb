FactoryBot.define do
  factory :meeting_error_report do
    association :meeting
    association :user
    description { "There appears to be an error in the qualifying time for the 100m Freestyle event. The time listed is significantly faster than expected." }
    status { "pending" }
  end
end
