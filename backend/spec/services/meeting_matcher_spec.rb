require "rails_helper"

RSpec.describe MeetingMatcher do
  let(:region) { Region.find_or_create_by!(name: "North East", code: "NE") }

  describe ".find_live_meeting" do
    context "when license_number matches meet_number in LiveMeeting" do
      let!(:live_meeting) do
        LiveMeeting.create!(
          name: "Test Swimming Meet 2025 - 4NE999999",
          meet_number: "99999",
          start_date: Date.today + 7.days,
          course_type: "25",
          region: region
        )
      end

      it "finds the live meeting when license matches meet_number" do
        meeting = Meeting.new(
          name: "Test Swimming Meet 2025",
          license_number: "99999"
        )

        result = MeetingMatcher.find_live_meeting(meeting)
        expect(result).to eq(live_meeting)
      end
    end

    context "when license_number is in the LiveMeeting name" do
      let!(:live_meeting) do
        LiveMeeting.create!(
          name: "Another Test Meet 2025 - 4NE999998",
          meet_number: "99998",
          start_date: Date.today + 7.days,
          course_type: "25",
          region: region
        )
      end

      it "finds the live meeting by extracting license from name" do
        meeting = Meeting.new(
          name: "Another Test Meet 2025",
          license_number: "4NE999998"
        )

        result = MeetingMatcher.find_live_meeting(meeting)
        expect(result).to eq(live_meeting)
      end
    end

    context "when license_number is in the Meeting name but not set explicitly" do
      let!(:live_meeting) do
        LiveMeeting.create!(
          name: "Third Test Meet 2025 - 4SE999997",
          meet_number: "99997",
          start_date: Date.today + 7.days,
          course_type: "25",
          region: region
        )
      end

      it "extracts license from meeting name and matches" do
        meeting = Meeting.new(
          name: "Third Test Meet 2025 - 4SE999997",
          license_number: nil
        )

        result = MeetingMatcher.find_live_meeting(meeting)
        expect(result).to eq(live_meeting)
      end
    end

    context "when no match is found" do
      it "returns nil" do
        meeting = Meeting.new(
          name: "Unknown Meeting",
          license_number: "NONEXISTENT123"
        )

        result = MeetingMatcher.find_live_meeting(meeting)
        expect(result).to be_nil
      end
    end

    context "when license_number is nil" do
      it "returns nil" do
        meeting = Meeting.new(
          name: "Meeting Without License",
          license_number: nil
        )

        result = MeetingMatcher.find_live_meeting(meeting)
        expect(result).to be_nil
      end
    end
  end

  describe ".extract_license_from_name" do
    it "extracts license number in format 4NE252206" do
      name = "Darlington ASC Club Gala 4 2025 - 4NE252206"
      result = MeetingMatcher.extract_license_from_name(name)
      expect(result).to eq("4NE252206")
    end

    it "extracts license number in format 3SE251839" do
      name = "Maidstone Club Championships 2025 - 3SE251839"
      result = MeetingMatcher.extract_license_from_name(name)
      expect(result).to eq("3SE251839")
    end

    it "extracts license number in format 4WMID252313" do
      name = "Droitwich Dolphins Club Championships 2025 - 4WMID252313"
      result = MeetingMatcher.extract_license_from_name(name)
      expect(result).to eq("4WMID252313")
    end

    it "returns nil when no license number is present" do
      name = "Some Meeting Without License"
      result = MeetingMatcher.extract_license_from_name(name)
      expect(result).to be_nil
    end

    it "returns nil when name is nil" do
      result = MeetingMatcher.extract_license_from_name(nil)
      expect(result).to be_nil
    end
  end
end
