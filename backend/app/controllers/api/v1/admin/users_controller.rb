module Api
  module V1
    module Admin
      class UsersController < ApplicationController
        before_action :require_admin!
        before_action :set_user, only: [ :show, :update, :destroy ]

        # GET /api/v1/admin/users
        def index
          @users = User.all.order(created_at: :desc)
          render json: @users.map { |user| user_json(user) }
        end

        # GET /api/v1/admin/users/:id
        def show
          render json: user_json(@user)
        end

        # PATCH /api/v1/admin/users/:id
        def update
          if @user.update(user_params)
            render json: user_json(@user)
          else
            render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/admin/users/:id
        def destroy
          if @user == current_user
            render json: { error: "You cannot delete your own account" }, status: :unprocessable_entity
            return
          end

          @user.destroy
          head :no_content
        end

        # POST /api/v1/admin/users/:id/promote
        def promote
          @user = User.find(params[:id])

          if @user.update(role: "admin")
            render json: user_json(@user)
          else
            render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # POST /api/v1/admin/users/:id/demote
        def demote
          @user = User.find(params[:id])

          if @user == current_user
            render json: { error: "You cannot demote yourself" }, status: :unprocessable_entity
            return
          end

          if @user.update(role: "user")
            render json: user_json(@user)
          else
            render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def require_admin!
          return if performed? # Skip if response already rendered (e.g., by authenticate_user!)

          unless current_user&.admin?
            render json: { error: "Unauthorized. Admin access required." }, status: :forbidden
          end
        end

        def set_user
          @user = User.find(params[:id])
        end

        def user_params
          params.require(:user).permit(:email, :role)
        end

        def user_json(user)
          {
            id: user.id,
            email: user.email,
            role: user.role,
            created_at: user.created_at,
            swimmers_count: user.swimmers.count
          }
        end
      end
    end
  end
end
