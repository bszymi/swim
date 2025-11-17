require "rails_helper"

RSpec.describe LiveMeeting, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:course_type) }
    it { should validate_inclusion_of(:course_type).in_array(%w[25 50]) }
  end

  describe "associations" do
    it { should belong_to(:region).optional }
    it { should belong_to(:county).optional }
  end

  describe "scopes" do
    let!(:past_meeting) { LiveMeeting.create!(name: "Past Meet", start_date: 1.week.ago, course_type: "25") }
    let!(:today_meeting) { LiveMeeting.create!(name: "Today Meet", start_date: Date.current, course_type: "50") }
    let!(:tomorrow_meeting) { LiveMeeting.create!(name: "Tomorrow Meet", start_date: Date.current + 1.day, course_type: "25") }
    let!(:next_week_meeting) { LiveMeeting.create!(name: "Next Week", start_date: Date.current + 5.days, course_type: "50") }
    let!(:far_future_meeting) { LiveMeeting.create!(name: "Far Future", start_date: Date.current + 30.days, course_type: "25") }

    describe ".upcoming" do
      it "returns meetings from today onwards ordered by start_date" do
        expect(LiveMeeting.upcoming).to eq([
          today_meeting,
          tomorrow_meeting,
          next_week_meeting,
          far_future_meeting
        ])
      end

      it "does not include past meetings" do
        expect(LiveMeeting.upcoming).not_to include(past_meeting)
      end
    end

    describe ".today" do
      it "returns only meetings starting today" do
        expect(LiveMeeting.today).to eq([ today_meeting ])
      end

      it "does not include past or future meetings" do
        expect(LiveMeeting.today).not_to include(past_meeting, tomorrow_meeting)
      end
    end

    describe ".this_week" do
      it "returns meetings within next 7 days" do
        this_week = LiveMeeting.this_week
        expect(this_week).to include(today_meeting, tomorrow_meeting, next_week_meeting)
        expect(this_week).not_to include(past_meeting, far_future_meeting)
      end
    end

    describe ".by_region" do
      let(:region) { Region.create!(name: "East Midlands", code: "EM") }
      let!(:regional_meeting) { LiveMeeting.create!(name: "Regional Meet", start_date: Date.current, course_type: "25", region: region) }

      it "returns meetings for specified region" do
        expect(LiveMeeting.by_region(region.id)).to eq([ regional_meeting ])
      end

      it "does not return meetings from other regions" do
        expect(LiveMeeting.by_region(region.id)).not_to include(today_meeting)
      end
    end
  end

  describe "#ongoing?" do
    context "when meeting has no end_date" do
      let(:meeting) { LiveMeeting.new(start_date: Date.current - 1.day) }

      it "returns true if start_date is in the past" do
        expect(meeting.ongoing?).to be true
      end

      it "returns true if start_date is today" do
        meeting.start_date = Date.current
        expect(meeting.ongoing?).to be true
      end

      it "returns false if start_date is in the future" do
        meeting.start_date = Date.current + 1.day
        expect(meeting.ongoing?).to be false
      end
    end

    context "when meeting has an end_date" do
      let(:meeting) { LiveMeeting.new(start_date: Date.current - 2.days, end_date: Date.current + 1.day) }

      it "returns true if current date is between start and end" do
        expect(meeting.ongoing?).to be true
      end

      it "returns true if current date equals start_date" do
        meeting.start_date = Date.current
        expect(meeting.ongoing?).to be true
      end

      it "returns true if current date equals end_date" do
        meeting.end_date = Date.current
        expect(meeting.ongoing?).to be true
      end

      it "returns false if current date is after end_date" do
        meeting.start_date = Date.current - 10.days
        meeting.end_date = Date.current - 1.day
        expect(meeting.ongoing?).to be false
      end

      it "returns false if current date is before start_date" do
        meeting.start_date = Date.current + 1.day
        meeting.end_date = Date.current + 3.days
        expect(meeting.ongoing?).to be false
      end
    end
  end

  describe "#course_type_display" do
    it "returns '25m (Short Course)' for course_type 25" do
      meeting = LiveMeeting.new(course_type: "25")
      expect(meeting.course_type_display).to eq("25m (Short Course)")
    end

    it "returns '50m (Long Course)' for course_type 50" do
      meeting = LiveMeeting.new(course_type: "50")
      expect(meeting.course_type_display).to eq("50m (Long Course)")
    end
  end
end
