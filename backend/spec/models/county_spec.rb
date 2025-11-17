require "rails_helper"

RSpec.describe County, type: :model do
  let(:region) { Region.create!(name: "East Midlands", code: "EM") }

  describe "validations" do
    subject { County.create(name: "Nottinghamshire", region: region) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).scoped_to(:region_id) }
  end

  describe "associations" do
    it { should belong_to(:region) }
    it { should have_many(:live_meetings).dependent(:nullify) }
  end

  describe "scoped uniqueness" do
    let!(:county1) { County.create!(name: "Nottinghamshire", region: region) }
    let(:region2) { Region.create!(name: "West Midlands", code: "WM") }

    it "allows same county name in different regions" do
      county2 = County.new(name: "Nottinghamshire", region: region2)
      expect(county2).to be_valid
    end

    it "does not allow duplicate county name in same region" do
      duplicate_county = County.new(name: "Nottinghamshire", region: region)
      expect(duplicate_county).not_to be_valid
    end
  end

  describe "destroying a county" do
    let(:county) { County.create!(name: "Nottinghamshire", region: region) }
    let!(:live_meeting) { LiveMeeting.create!(name: "Test Meet", start_date: Date.today, course_type: "25", county: county) }

    it "nullifies county_id on associated live_meetings" do
      county.destroy
      expect(live_meeting.reload.county_id).to be_nil
    end
  end
end
