FactoryBot.define do
  factory :meeting, class: "Meeting" do
    name { "National Championships 2025" }
    season { "2024-2025" }
    pool_required { "LC" }
    window_start { Date.today - 3.months }
    window_end { Date.today }
    age_rule_type { "calendar_year" }
    age_rule_date { Date.new(Date.today.year, 12, 31) }
  end
end
