require "rails_helper"

RSpec.describe "Api::V1::Admin::Users", type: :request do
  let(:admin_user) { create(:user, role: "admin") }
  let(:regular_user) { create(:user, role: "user") }
  let(:other_user) { create(:user, email: "other@example.com", role: "user") }

  describe "GET /api/v1/admin/users" do
    context "when user is admin" do
      it "returns all users" do
        get "/api/v1/admin/users", headers: auth_headers(admin_user)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json.length).to be >= 1
      end
    end

    context "when user is not admin" do
      it "returns forbidden" do
        get "/api/v1/admin/users", headers: auth_headers(regular_user)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        get "/api/v1/admin/users"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/admin/users/:id/promote" do
    context "when admin promotes a user" do
      it "changes user role to admin" do
        post "/api/v1/admin/users/#{regular_user.id}/promote", headers: auth_headers(admin_user)

        expect(response).to have_http_status(:ok)
        expect(regular_user.reload.role).to eq("admin")
      end
    end

    context "when non-admin tries to promote" do
      it "returns forbidden" do
        post "/api/v1/admin/users/#{other_user.id}/promote", headers: auth_headers(regular_user)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST /api/v1/admin/users/:id/demote" do
    let(:another_admin) { create(:user, email: "admin2@example.com", role: "admin") }

    context "when admin demotes another admin" do
      it "changes user role to user" do
        post "/api/v1/admin/users/#{another_admin.id}/demote", headers: auth_headers(admin_user)

        expect(response).to have_http_status(:ok)
        expect(another_admin.reload.role).to eq("user")
      end
    end

    context "when admin tries to demote themselves" do
      it "returns error" do
        post "/api/v1/admin/users/#{admin_user.id}/demote", headers: auth_headers(admin_user)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("cannot demote yourself")
      end
    end
  end

  describe "DELETE /api/v1/admin/users/:id" do
    context "when admin deletes another user" do
      it "deletes the user" do
        other_user # Create the user before counting

        expect {
          delete "/api/v1/admin/users/#{other_user.id}", headers: auth_headers(admin_user)
        }.to change(User, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end
    end

    context "when admin tries to delete themselves" do
      it "returns error" do
        delete "/api/v1/admin/users/#{admin_user.id}", headers: auth_headers(admin_user)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("cannot delete your own account")
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
