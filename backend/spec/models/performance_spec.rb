require "rails_helper"

RSpec.describe Performance, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:swimmer) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:time_seconds) }
    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_presence_of(:stroke) }
    it { is_expected.to validate_presence_of(:distance_m) }
    it { is_expected.to validate_presence_of(:course_type) }

    it { is_expected.to validate_inclusion_of(:stroke).in_array(%w[FREE BACK BREAST FLY IM]) }
    it { is_expected.to validate_inclusion_of(:distance_m).in_array([ 50, 100, 200, 400, 800, 1500 ]) }
    it { is_expected.to validate_inclusion_of(:course_type).in_array(%w[SC LC]) }
  end

  describe "scopes" do
    let(:swimmer) { Swimmer.create!(first_name: "John", last_name: "Doe", dob: Date.new(2010, 1, 1), sex: "M") }

    describe ".in_window" do
      it "filters performances within date range" do
        perf1 = Performance.create!(
          swimmer: swimmer,
          stroke: "FREE",
          distance_m: 100,
          course_type: "LC",
          time_seconds: 60.0,
          date: Date.new(2023, 5, 1)
        )
        perf2 = Performance.create!(
          swimmer: swimmer,
          stroke: "FREE",
          distance_m: 100,
          course_type: "LC",
          time_seconds: 61.0,
          date: Date.new(2023, 7, 1)
        )
        perf3 = Performance.create!(
          swimmer: swimmer,
          stroke: "FREE",
          distance_m: 100,
          course_type: "LC",
          time_seconds: 62.0,
          date: Date.new(2023, 9, 1)
        )

        result = Performance.in_window(Date.new(2023, 6, 1), Date.new(2023, 8, 1))
        expect(result).to contain_exactly(perf2)
      end

      it "returns all performances when dates are nil" do
        perf = Performance.create!(
          swimmer: swimmer,
          stroke: "FREE",
          distance_m: 100,
          course_type: "LC",
          time_seconds: 60.0,
          date: Date.new(2023, 5, 1)
        )

        result = Performance.in_window(nil, nil)
        expect(result).to include(perf)
      end
    end

    describe ".with_min_license" do
      it "filters performances by minimum license level" do
        perf1 = Performance.create!(
          swimmer: swimmer,
          stroke: "FREE",
          distance_m: 100,
          course_type: "LC",
          time_seconds: 60.0,
          date: Date.today,
          license_level: 1
        )
        perf2 = Performance.create!(
          swimmer: swimmer,
          stroke: "BACK",
          distance_m: 100,
          course_type: "LC",
          time_seconds: 65.0,
          date: Date.today,
          license_level: 3
        )

        result = Performance.with_min_license(2)
        expect(result).to contain_exactly(perf2)
      end

      it "returns all performances when license level is nil" do
        perf = Performance.create!(
          swimmer: swimmer,
          stroke: "FREE",
          distance_m: 100,
          course_type: "LC",
          time_seconds: 60.0,
          date: Date.today
        )

        result = Performance.with_min_license(nil)
        expect(result).to include(perf)
      end
    end

    describe ".for_event" do
      it "filters by stroke and distance" do
        perf1 = Performance.create!(
          swimmer: swimmer,
          stroke: "FREE",
          distance_m: 100,
          course_type: "LC",
          time_seconds: 60.0,
          date: Date.today
        )
        perf2 = Performance.create!(
          swimmer: swimmer,
          stroke: "BACK",
          distance_m: 100,
          course_type: "LC",
          time_seconds: 65.0,
          date: Date.today
        )
        perf3 = Performance.create!(
          swimmer: swimmer,
          stroke: "FREE",
          distance_m: 200,
          course_type: "LC",
          time_seconds: 130.0,
          date: Date.today
        )

        result = Performance.for_event("FREE", 100)
        expect(result).to contain_exactly(perf1)
      end
    end
  end

  describe "#time_formatted" do
    let(:swimmer) { Swimmer.create!(first_name: "John", last_name: "Doe", dob: Date.new(2010, 1, 1), sex: "M") }

    it "formats times under a minute correctly" do
      performance = Performance.new(
        swimmer: swimmer,
        stroke: "FREE",
        distance_m: 50,
        course_type: "LC",
        time_seconds: 29.52,
        date: Date.today
      )
      expect(performance.time_formatted).to eq("29.52")
    end

    it "formats times over a minute correctly" do
      performance = Performance.new(
        swimmer: swimmer,
        stroke: "FREE",
        distance_m: 100,
        course_type: "LC",
        time_seconds: 65.23,
        date: Date.today
      )
      expect(performance.time_formatted).to eq("1:05.23")
    end

    it "formats multi-minute times correctly" do
      performance = Performance.new(
        swimmer: swimmer,
        stroke: "FREE",
        distance_m: 400,
        course_type: "LC",
        time_seconds: 305.67,
        date: Date.today
      )
      expect(performance.time_formatted).to eq("5:05.67")
    end

    it "pads seconds correctly" do
      performance = Performance.new(
        swimmer: swimmer,
        stroke: "FREE",
        distance_m: 100,
        course_type: "LC",
        time_seconds: 60.09,
        date: Date.today
      )
      expect(performance.time_formatted).to eq("1:00.09")
    end
  end
end
