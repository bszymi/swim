require "rails_helper"

RSpec.describe "Regions API", type: :request do
  let!(:region1) { Region.create!(name: "East Midlands", code: "EM") }
  let!(:region2) { Region.create!(name: "West Midlands", code: "WM") }
  let!(:county1) { County.create!(name: "Nottinghamshire", region: region1) }
  let!(:county2) { County.create!(name: "Derbyshire", region: region1) }

  describe "GET /api/v1/regions" do
    it "returns all regions ordered by name" do
      get "/api/v1/regions", as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.count).to eq(2)
      expect(json.first["name"]).to eq("East Midlands")
      expect(json.last["name"]).to eq("West Midlands")
    end

    it "does not require authentication" do
      get "/api/v1/regions", as: :json
      expect(response).not_to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/regions/:id" do
    it "returns a specific region with counties" do
      get "/api/v1/regions/#{region1.id}", as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["name"]).to eq("East Midlands")
      expect(json["code"]).to eq("EM")
      expect(json["counties"]).to be_present
      expect(json["counties"].count).to eq(2)
    end

    it "returns 404 for non-existent region" do
      get "/api/v1/regions/99999", as: :json
      expect(response).to have_http_status(:not_found)
    end

    it "does not require authentication" do
      get "/api/v1/regions/#{region1.id}", as: :json
      expect(response).not_to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/regions/:id/counties" do
    it "returns all counties for a region ordered by name" do
      get "/api/v1/regions/#{region1.id}/counties", as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.count).to eq(2)
      expect(json.first["name"]).to eq("Derbyshire")
      expect(json.last["name"]).to eq("Nottinghamshire")
    end

    it "returns empty array for region with no counties" do
      get "/api/v1/regions/#{region2.id}/counties", as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to eq([])
    end

    it "returns 404 for non-existent region" do
      get "/api/v1/regions/99999/counties", as: :json
      expect(response).to have_http_status(:not_found)
    end

    it "does not require authentication" do
      get "/api/v1/regions/#{region1.id}/counties", as: :json
      expect(response).not_to have_http_status(:unauthorized)
    end
  end
end
