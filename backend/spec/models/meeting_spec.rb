require "rails_helper"

RSpec.describe Meeting, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:meeting_standards).dependent(:destroy) }
    it { is_expected.to have_one(:meet_rule).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "nested attributes" do
    it { is_expected.to accept_nested_attributes_for(:meeting_standards).allow_destroy(true) }
    it { is_expected.to accept_nested_attributes_for(:meet_rule) }
  end

  describe "#age_reference_date" do
    context "when age_rule_type includes 'age' and 'date' and age_rule_date is present" do
      it "returns the age_rule_date" do
        meet_set = Meeting.new(
          name: "Test Meet",
          age_rule_type: "age_on_date",
          age_rule_date: Date.new(2023, 9, 1)
        )
        expect(meet_set.age_reference_date).to eq(Date.new(2023, 9, 1))
      end

      it "is case insensitive for age_rule_type" do
        meet_set = Meeting.new(
          name: "Test Meet",
          age_rule_type: "AGE_ON_DATE",
          age_rule_date: Date.new(2023, 9, 1)
        )
        expect(meet_set.age_reference_date).to eq(Date.new(2023, 9, 1))
      end
    end

    context "when age_rule_type is calendar_year with season" do
      it "returns Dec 31 of the season year" do
        meet_set = Meeting.new(
          name: "Test Meet",
          age_rule_type: "calendar_year",
          season: "2023"
        )
        expect(meet_set.age_reference_date).to eq(Date.new(2023, 12, 31))
      end
    end

    context "when age_rule_type is calendar_year without season" do
      it "returns Dec 31 of the window_end year when present" do
        meet_set = Meeting.new(
          name: "Test Meet",
          age_rule_type: "calendar_year",
          window_end: Date.new(2023, 6, 30)
        )
        expect(meet_set.age_reference_date).to eq(Date.new(2023, 12, 31))
      end

      it "returns Dec 31 of current year when window_end is nil" do
        meet_set = Meeting.new(
          name: "Test Meet",
          age_rule_type: "calendar_year"
        )
        expected_date = Date.new(Date.today.year, 12, 31)
        expect(meet_set.age_reference_date).to eq(expected_date)
      end
    end

    context "when using default behavior" do
      it "returns Dec 31 of window_end year" do
        meet_set = Meeting.new(
          name: "Test Meet",
          window_end: Date.new(2023, 6, 30)
        )
        expect(meet_set.age_reference_date).to eq(Date.new(2023, 12, 31))
      end

      it "returns Dec 31 of current year when window_end is nil" do
        meet_set = Meeting.new(name: "Test Meet")
        expected_date = Date.new(Date.today.year, 12, 31)
        expect(meet_set.age_reference_date).to eq(expected_date)
      end
    end
  end
end
