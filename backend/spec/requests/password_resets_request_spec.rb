require "rails_helper"

RSpec.describe "PasswordResets", type: :request do
  let(:user) { User.create!(email: "test@example.com", password: "password123") }

  describe "POST /api/v1/password_resets" do
    context "with valid email" do
      it "returns success message" do
        post "/api/v1/password_resets", params: { email: user.email }, as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["message"]).to eq("If an account exists with that email, you will receive password reset instructions.")
      end

      it "generates password reset token for user" do
        expect {
          post "/api/v1/password_resets", params: { email: user.email }, as: :json
        }.to change { user.reload.reset_password_token }.from(nil)
      end

      it "sets reset_password_sent_at timestamp" do
        expect {
          post "/api/v1/password_resets", params: { email: user.email }, as: :json
        }.to change { user.reload.reset_password_sent_at }.from(nil)
      end

      it "sends password reset email" do
        expect {
          post "/api/v1/password_resets", params: { email: user.email }, as: :json
        }.to change { ActionMailer::Base.deliveries.count }.by(1)

        mail = ActionMailer::Base.deliveries.last
        expect(mail.to).to eq([ user.email ])
        expect(mail.subject).to eq("Reset Your Password - Swim Meet Manager")
      end
    end

    context "with non-existent email" do
      it "returns same success message to prevent email enumeration" do
        post "/api/v1/password_resets", params: { email: "nonexistent@example.com" }, as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["message"]).to eq("If an account exists with that email, you will receive password reset instructions.")
      end

      it "does not send email" do
        expect {
          post "/api/v1/password_resets", params: { email: "nonexistent@example.com" }, as: :json
        }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context "with case-insensitive email" do
      it "finds user regardless of email case" do
        post "/api/v1/password_resets", params: { email: user.email.upcase }, as: :json

        expect(response).to have_http_status(:ok)
        expect(user.reload.reset_password_token).not_to be_nil
      end
    end
  end

  describe "PUT /api/v1/password_resets/:token" do
    let!(:user_with_token) do
      user.generate_password_reset_token!
      user
    end

    context "with valid token and password" do
      it "returns success message" do
        put "/api/v1/password_resets/#{user_with_token.reset_password_token}",
            params: { password: "newpassword123" }, as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["message"]).to eq("Password has been reset successfully.")
      end

      it "updates user password" do
        old_password_digest = user_with_token.encrypted_password

        put "/api/v1/password_resets/#{user_with_token.reset_password_token}",
            params: { password: "newpassword123" }, as: :json

        user_with_token.reload
        expect(user_with_token.encrypted_password).not_to eq(old_password_digest)
        expect(user_with_token.valid_password?("newpassword123")).to be true
      end

      it "clears reset token and timestamp" do
        put "/api/v1/password_resets/#{user_with_token.reset_password_token}",
            params: { password: "newpassword123" }, as: :json

        user_with_token.reload
        expect(user_with_token.reset_password_token).to be_nil
        expect(user_with_token.reset_password_sent_at).to be_nil
      end
    end

    context "with invalid token" do
      it "returns error message" do
        put "/api/v1/password_resets/invalid_token",
            params: { password: "newpassword123" }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Password reset link is invalid or has expired.")
      end

      it "does not update password" do
        old_password_digest = user_with_token.encrypted_password

        put "/api/v1/password_resets/invalid_token",
            params: { password: "newpassword123" }, as: :json

        expect(user_with_token.reload.encrypted_password).to eq(old_password_digest)
      end
    end

    context "with expired token" do
      it "returns error message" do
        user_with_token.update_column(:reset_password_sent_at, 3.hours.ago)

        put "/api/v1/password_resets/#{user_with_token.reset_password_token}",
            params: { password: "newpassword123" }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Password reset link is invalid or has expired.")
      end
    end

    context "with invalid password" do
      it "returns validation errors" do
        put "/api/v1/password_resets/#{user_with_token.reset_password_token}",
            params: { password: "short" }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
      end

      it "does not clear reset token" do
        put "/api/v1/password_resets/#{user_with_token.reset_password_token}",
            params: { password: "short" }, as: :json

        expect(user_with_token.reload.reset_password_token).not_to be_nil
      end
    end
  end
end
