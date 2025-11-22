require "rails_helper"

RSpec.describe Region, type: :model do
  describe "validations" do
    subject { Region.create(name: "East Midlands", code: "EM") }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:code) }
    it { should validate_uniqueness_of(:code) }
  end

  describe "associations" do
    it { should have_many(:counties).dependent(:destroy) }
    it { should have_many(:live_meetings).dependent(:nullify) }
  end

  describe "destroying a region" do
    let(:region) { Region.create!(name: "East Midlands", code: "EM") }
    let!(:county) { County.create!(name: "Nottinghamshire", region: region) }
    let!(:live_meeting) { LiveMeeting.create!(name: "Test Meet", start_date: Date.today, course_type: "25", region: region) }

    it "destroys associated counties" do
      expect { region.destroy }.to change { County.count }.by(-1)
    end

    it "nullifies region_id on associated live_meetings" do
      region.destroy
      expect(live_meeting.reload.region_id).to be_nil
    end
  end
end
