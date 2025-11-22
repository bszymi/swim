require "rails_helper"

RSpec.describe "LiveMeetings API", type: :request do
  let(:region) { Region.create!(name: "East Midlands", code: "EM") }
  let(:county) { County.create!(name: "Nottinghamshire", region: region) }
  let(:user) { User.create!(email: "test@example.com", password: "password123") }

  let!(:past_meeting) { LiveMeeting.create!(name: "Past Meet", start_date: 1.week.ago, course_type: "25") }
  let!(:today_meeting) { LiveMeeting.create!(name: "Today Meet", start_date: Date.current, course_type: "50", region: region) }
  let!(:upcoming_meeting) { LiveMeeting.create!(name: "Upcoming Meet", start_date: Date.current + 5.days, course_type: "25", county: county, region: region) }

  describe "GET /api/v1/live_meetings" do
    it "returns upcoming meetings" do
      get "/api/v1/live_meetings", as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.count).to eq(2)
      expect(json.map { |m| m["name"] }).to contain_exactly("Today Meet", "Upcoming Meet")
    end

    it "includes region and county associations" do
      get "/api/v1/live_meetings", as: :json

      json = JSON.parse(response.body)
      meeting = json.find { |m| m["name"] == "Upcoming Meet" }
      expect(meeting["region"]["name"]).to eq("East Midlands")
      expect(meeting["county"]["name"]).to eq("Nottinghamshire")
    end

    it "filters by region_id" do
      get "/api/v1/live_meetings", params: { region_id: region.id }, as: :json

      json = JSON.parse(response.body)
      expect(json.count).to eq(2)
      expect(json.all? { |m| m["region_id"] == region.id }).to be true
    end

    it "filters by start_date" do
      get "/api/v1/live_meetings", params: { start_date: Date.current + 1.day }, as: :json

      json = JSON.parse(response.body)
      expect(json.count).to eq(1)
      expect(json.first["name"]).to eq("Upcoming Meet")
    end

    it "filters by end_date" do
      get "/api/v1/live_meetings", params: { end_date: Date.current }, as: :json

      json = JSON.parse(response.body)
      expect(json.count).to eq(1)
      expect(json.first["name"]).to eq("Today Meet")
    end

    it "filters by course_type" do
      get "/api/v1/live_meetings", params: { course_type: "25" }, as: :json

      json = JSON.parse(response.body)
      expect(json.count).to eq(1)
      expect(json.first["name"]).to eq("Upcoming Meet")
    end

    it "does not include past meetings" do
      get "/api/v1/live_meetings", as: :json

      json = JSON.parse(response.body)
      expect(json.map { |m| m["name"] }).not_to include("Past Meet")
    end

    it "does not require authentication" do
      get "/api/v1/live_meetings", as: :json
      expect(response).not_to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/live_meetings/:id" do
    it "returns a specific meeting with associations" do
      get "/api/v1/live_meetings/#{upcoming_meeting.id}", as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["name"]).to eq("Upcoming Meet")
      expect(json["region"]["name"]).to eq("East Midlands")
      expect(json["county"]["name"]).to eq("Nottinghamshire")
    end

    it "returns 404 for non-existent meeting" do
      get "/api/v1/live_meetings/99999", as: :json
      expect(response).to have_http_status(:not_found)
    end

    it "does not require authentication" do
      get "/api/v1/live_meetings/#{upcoming_meeting.id}", as: :json
      expect(response).not_to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/live_meetings/today" do
    it "returns meetings happening today with count" do
      get "/api/v1/live_meetings/today", as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["date"]).to eq(Date.current.to_s)
      expect(json["count"]).to eq(1)
      expect(json["meetings"].count).to eq(1)
      expect(json["meetings"].first["name"]).to eq("Today Meet")
    end

    it "includes region and county in meetings" do
      get "/api/v1/live_meetings/today", as: :json

      json = JSON.parse(response.body)
      meeting = json["meetings"].first
      expect(meeting["region"]["name"]).to eq("East Midlands")
    end

    it "returns empty array when no meetings today" do
      today_meeting.destroy

      get "/api/v1/live_meetings/today", as: :json

      json = JSON.parse(response.body)
      expect(json["count"]).to eq(0)
      expect(json["meetings"]).to eq([])
    end

    it "does not require authentication" do
      get "/api/v1/live_meetings/today", as: :json
      expect(response).not_to have_http_status(:unauthorized)
    end
  end
end
