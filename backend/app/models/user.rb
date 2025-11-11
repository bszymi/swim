class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :user_swimmers, dependent: :destroy
  has_many :swimmers, through: :user_swimmers

  def admin?
    # TODO: Add admin field to users table if needed
    false
  end

  def generate_password_reset_token!
    self.reset_password_token = SecureRandom.urlsafe_base64
    self.reset_password_sent_at = Time.current
    save(validate: false)
  end

  def password_reset_valid?
    reset_password_sent_at && reset_password_sent_at > 2.hours.ago
  end
end
