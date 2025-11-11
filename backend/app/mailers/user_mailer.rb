class UserMailer < ApplicationMailer
  default from: "noreply@swimmeetmanager.com"

  def password_reset(user)
    @user = user
    @reset_url = "#{ENV['FRONTEND_URL']}/reset-password/#{user.reset_password_token}"

    mail(
      to: @user.email,
      subject: "Reset Your Password - Swim Meet Manager"
    )
  end
end
