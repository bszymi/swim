module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_user!, only: [ :login, :signup ]

      def signup
        user = User.new(signup_params)

        if user.save
          token = encode_token(user.id)
          render json: {
            user: user_json(user),
            token: token
          }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def login
        user = User.find_by(email: login_params[:email])

        if user&.valid_password?(login_params[:password])
          token = encode_token(user.id)
          render json: {
            user: user_json(user),
            token: token
          }
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      def logout
        # With JWT, logout is handled client-side by removing the token
        render json: { message: "Logged out successfully" }
      end

      def me
        render json: { user: user_json(current_user) }
      end

      private

      def signup_params
        params.require(:user).permit(:email, :password, :password_confirmation)
      end

      def login_params
        params.require(:user).permit(:email, :password)
      end

      def user_json(user)
        {
          id: user.id,
          email: user.email,
          role: user.role,
          is_admin: user.admin?,
          created_at: user.created_at
        }
      end

      def encode_token(user_id)
        payload = { user_id: user_id, exp: 24.hours.from_now.to_i }
        JWT.encode(payload, Rails.application.credentials.secret_key_base || ENV["SECRET_KEY_BASE"])
      end
    end
  end
end
