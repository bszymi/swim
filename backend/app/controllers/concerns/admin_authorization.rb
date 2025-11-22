module AdminAuthorization
  extend ActiveSupport::Concern

  included do
    before_action :check_admin, if: :admin_required?
  end

  private

  def check_admin
    return if current_user&.admin?

    render json: { error: "Unauthorized. Admin access required." }, status: :forbidden
  end

  def admin_required?
    false # Override in controllers that need admin access
  end

  def require_admin!
    return if current_user&.admin?

    render json: { error: "Unauthorized. Admin access required." }, status: :forbidden
  end
end
