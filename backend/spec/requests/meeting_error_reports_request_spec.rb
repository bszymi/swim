require "rails_helper"

RSpec.describe "Api::V1::MeetingErrorReports", type: :request do
  let(:admin_user) { create(:user, role: "admin") }
  let(:regular_user) { create(:user, role: "user") }
  let(:meeting) { create(:meeting) }

  describe "GET /api/v1/meeting_error_reports" do
    let!(:pending_report) { create(:meeting_error_report, status: "pending") }
    let!(:resolved_report) { create(:meeting_error_report, status: "resolved") }

    context "when user is admin" do
      it "returns all reports" do
        get "/api/v1/meeting_error_reports", headers: auth_headers(admin_user)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json.length).to eq(2)
      end

      it "filters by status when provided" do
        get "/api/v1/meeting_error_reports", params: { status: "pending" }, headers: auth_headers(admin_user)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json.length).to eq(1)
        expect(json.first["status"]).to eq("pending")
      end
    end

    context "when user is not admin" do
      it "returns forbidden" do
        get "/api/v1/meeting_error_reports", headers: auth_headers(regular_user)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        get "/api/v1/meeting_error_reports"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/meeting_error_reports" do
    let(:valid_params) do
      {
        meeting_id: meeting.id,
        description: "The qualifying time for 100m Freestyle appears to be incorrect for age group 12-13."
      }
    end

    context "when user is authenticated" do
      it "creates a new error report" do
        expect {
          post "/api/v1/meeting_error_reports", params: valid_params, headers: auth_headers(regular_user)
        }.to change(MeetingErrorReport, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["error_report"]["description"]).to eq(valid_params[:description])
        expect(json["error_report"]["status"]).to eq("pending")
      end

      it "associates the report with the current user" do
        post "/api/v1/meeting_error_reports", params: valid_params, headers: auth_headers(regular_user)

        report = MeetingErrorReport.last
        expect(report.user).to eq(regular_user)
      end

      it "returns error for invalid description" do
        invalid_params = valid_params.merge(description: "short")

        post "/api/v1/meeting_error_reports", params: invalid_params, headers: auth_headers(regular_user)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
      end
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        post "/api/v1/meeting_error_reports", params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PUT /api/v1/meeting_error_reports/:id" do
    let!(:error_report) { create(:meeting_error_report, status: "pending") }

    context "when admin updates status" do
      it "marks report as resolved" do
        put "/api/v1/meeting_error_reports/#{error_report.id}",
            params: { status: "resolved" },
            headers: auth_headers(admin_user)

        expect(response).to have_http_status(:ok)
        expect(error_report.reload.status).to eq("resolved")
      end

      it "can reopen a resolved report" do
        error_report.update(status: "resolved")

        put "/api/v1/meeting_error_reports/#{error_report.id}",
            params: { status: "pending" },
            headers: auth_headers(admin_user)

        expect(response).to have_http_status(:ok)
        expect(error_report.reload.status).to eq("pending")
      end
    end

    context "when non-admin tries to update" do
      it "returns forbidden" do
        put "/api/v1/meeting_error_reports/#{error_report.id}",
            params: { status: "resolved" },
            headers: auth_headers(regular_user)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        put "/api/v1/meeting_error_reports/#{error_report.id}",
            params: { status: "resolved" }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  def auth_headers(user)
    token = JWT.encode(
      { user_id: user.id, exp: 24.hours.from_now.to_i },
      Rails.application.credentials.secret_key_base || ENV["SECRET_KEY_BASE"]
    )
    { "Authorization" => "Bearer #{token}" }
  end
end
