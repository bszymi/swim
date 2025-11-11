require "rails_helper"

RSpec.describe MeetingStandard, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:meeting) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:stroke) }
    it { is_expected.to validate_presence_of(:distance_m) }
    it { is_expected.to validate_presence_of(:pool_of_standard) }
    it { is_expected.to validate_presence_of(:standard_type) }
    it { is_expected.to validate_presence_of(:time_seconds) }

    it { is_expected.to validate_inclusion_of(:stroke).in_array(%w[FREE BACK BREAST FLY IM]) }
    it { is_expected.to validate_inclusion_of(:distance_m).in_array([ 50, 100, 200, 400, 800, 1500 ]) }
  end

  describe "scopes" do
    let(:meet_set) { Meeting.create!(name: "Test Meet") }

    describe ".for_event" do
      it "filters by stroke and distance" do
        row1 = MeetingStandard.create!(
          meeting: meet_set,
          stroke: "FREE",
          distance_m: 100,
          pool_of_standard: "LC",
          standard_type: "QUALIFY",
          time_seconds: 60.0,
          gender: "M"
        )
        row2 = MeetingStandard.create!(
          meeting: meet_set,
          stroke: "BACK",
          distance_m: 100,
          pool_of_standard: "LC",
          standard_type: "QUALIFY",
          time_seconds: 65.0,
          gender: "M"
        )

        result = MeetingStandard.for_event("FREE", 100)
        expect(result).to contain_exactly(row1)
      end
    end

    describe ".for_age" do
      it "filters standards that apply to the given age" do
        row1 = MeetingStandard.create!(
          meeting: meet_set,
          stroke: "FREE",
          distance_m: 100,
          pool_of_standard: "LC",
          standard_type: "QUALIFY",
          time_seconds: 60.0,
          gender: "M",
          age_min: 10,
          age_max: 12
        )
        row2 = MeetingStandard.create!(
          meeting: meet_set,
          stroke: "FREE",
          distance_m: 100,
          pool_of_standard: "LC",
          standard_type: "QUALIFY",
          time_seconds: 58.0,
          gender: "M",
          age_min: 13,
          age_max: 15
        )

        result = MeetingStandard.for_age(11)
        expect(result).to contain_exactly(row1)
      end

      it "includes rows with nil age_min" do
        row = MeetingStandard.create!(
          meeting: meet_set,
          stroke: "FREE",
          distance_m: 100,
          pool_of_standard: "LC",
          standard_type: "QUALIFY",
          time_seconds: 60.0,
          gender: "M",
          age_min: nil,
          age_max: 12
        )

        result = MeetingStandard.for_age(10)
        expect(result).to include(row)
      end

      it "includes rows with nil age_max" do
        row = MeetingStandard.create!(
          meeting: meet_set,
          stroke: "FREE",
          distance_m: 100,
          pool_of_standard: "LC",
          standard_type: "QUALIFY",
          time_seconds: 60.0,
          gender: "M",
          age_min: 13,
          age_max: nil
        )

        result = MeetingStandard.for_age(15)
        expect(result).to include(row)
      end
    end

    describe ".qualifying" do
      it "returns only QUALIFY type standards" do
        row1 = MeetingStandard.create!(
          meeting: meet_set,
          stroke: "FREE",
          distance_m: 100,
          pool_of_standard: "LC",
          standard_type: "QUALIFY",
          time_seconds: 60.0,
          gender: "M"
        )
        row2 = MeetingStandard.create!(
          meeting: meet_set,
          stroke: "FREE",
          distance_m: 100,
          pool_of_standard: "LC",
          standard_type: "CONSIDER",
          time_seconds: 62.0,
          gender: "M"
        )

        result = MeetingStandard.qualifying
        expect(result).to contain_exactly(row1)
      end
    end

    describe ".consideration" do
      it "returns only CONSIDER type standards" do
        row1 = MeetingStandard.create!(
          meeting: meet_set,
          stroke: "FREE",
          distance_m: 100,
          pool_of_standard: "LC",
          standard_type: "QUALIFY",
          time_seconds: 60.0,
          gender: "M"
        )
        row2 = MeetingStandard.create!(
          meeting: meet_set,
          stroke: "FREE",
          distance_m: 100,
          pool_of_standard: "LC",
          standard_type: "CONSIDER",
          time_seconds: 62.0,
          gender: "M"
        )

        result = MeetingStandard.consideration
        expect(result).to contain_exactly(row2)
      end
    end
  end

  describe "#applies_to_age?" do
    let(:meet_set) { Meeting.create!(name: "Test Meet") }

    it "returns true when age is within range" do
      row = MeetingStandard.new(
        meeting: meet_set,
        age_min: 10,
        age_max: 12
      )
      expect(row.applies_to_age?(11)).to be true
    end

    it "returns false when age is below minimum" do
      row = MeetingStandard.new(
        meeting: meet_set,
        age_min: 10,
        age_max: 12
      )
      expect(row.applies_to_age?(9)).to be false
    end

    it "returns false when age is above maximum" do
      row = MeetingStandard.new(
        meeting: meet_set,
        age_min: 10,
        age_max: 12
      )
      expect(row.applies_to_age?(13)).to be false
    end

    it "returns true when age_min is nil and age is below max" do
      row = MeetingStandard.new(
        meeting: meet_set,
        age_min: nil,
        age_max: 12
      )
      expect(row.applies_to_age?(10)).to be true
    end

    it "returns true when age_max is nil and age is above min" do
      row = MeetingStandard.new(
        meeting: meet_set,
        age_min: 13,
        age_max: nil
      )
      expect(row.applies_to_age?(15)).to be true
    end

    it "returns true when both age_min and age_max are nil" do
      row = MeetingStandard.new(
        meeting: meet_set,
        age_min: nil,
        age_max: nil
      )
      expect(row.applies_to_age?(20)).to be true
    end
  end

  describe "#age_group" do
    let(:meet_set) { Meeting.create!(name: "Test Meet") }

    it "returns range when both min and max are present and different" do
      row = MeetingStandard.new(
        meeting: meet_set,
        age_min: 10,
        age_max: 12
      )
      expect(row.age_group).to eq("10-12")
    end

    it "returns single age when min and max are the same" do
      row = MeetingStandard.new(
        meeting: meet_set,
        age_min: 10,
        age_max: 10
      )
      expect(row.age_group).to eq("10")
    end

    it "returns 'X+' format when only min is present" do
      row = MeetingStandard.new(
        meeting: meet_set,
        age_min: 13,
        age_max: nil
      )
      expect(row.age_group).to eq("13+")
    end

    it "returns 'Under X' when only max is present" do
      row = MeetingStandard.new(
        meeting: meet_set,
        age_min: nil,
        age_max: 12
      )
      expect(row.age_group).to eq("Under 12")
    end

    it "returns 'Open' when both are nil" do
      row = MeetingStandard.new(
        meeting: meet_set,
        age_min: nil,
        age_max: nil
      )
      expect(row.age_group).to eq("Open")
    end
  end

  describe "helper methods" do
    let(:meet_set) { Meeting.create!(name: "Test Meet") }

    describe "#sex" do
      it "returns the gender value" do
        row = MeetingStandard.new(
          meeting: meet_set,
          gender: "M"
        )
        expect(row.sex).to eq("M")
      end
    end

    describe "#course_type" do
      it "returns the pool_of_standard value" do
        row = MeetingStandard.new(
          meeting: meet_set,
          pool_of_standard: "LC"
        )
        expect(row.course_type).to eq("LC")
      end
    end

    describe "#qualifying_time_seconds" do
      it "returns the time_seconds value" do
        row = MeetingStandard.new(
          meeting: meet_set,
          time_seconds: 60.5
        )
        expect(row.qualifying_time_seconds).to eq(60.5)
      end
    end
  end
end
