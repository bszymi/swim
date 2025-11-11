module Api
  module V1
    class PasswordResetsController < ApplicationController
      skip_before_action :authenticate_user!

      # POST /api/v1/password_resets
      def create
        user = User.find_by(email: params[:email]&.downcase)

        if user
          user.generate_password_reset_token!
          UserMailer.password_reset(user).deliver_now
        end

        # Always return success to prevent email enumeration
        render json: {
          message: "If an account exists with that email, you will receive password reset instructions."
        }, status: :ok
      end

      # PUT /api/v1/password_resets/:token
      def update
        user = User.find_by(reset_password_token: params[:token])

        if user && user.password_reset_valid?
          if user.update(password: params[:password], reset_password_token: nil, reset_password_sent_at: nil)
            render json: { message: "Password has been reset successfully." }, status: :ok
          else
            render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
          end
        else
          render json: { error: "Password reset link is invalid or has expired." }, status: :unprocessable_entity
        end
      end
    end
  end
end
