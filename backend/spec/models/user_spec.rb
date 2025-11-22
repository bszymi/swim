require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
  end

  describe "associations" do
    it { should have_many(:user_swimmers).dependent(:destroy) }
    it { should have_many(:swimmers).through(:user_swimmers) }
  end

  describe "#generate_password_reset_token!" do
    let(:user) { User.create!(email: "test@example.com", password: "password123") }

    it "generates a reset_password_token" do
      expect {
        user.generate_password_reset_token!
      }.to change { user.reset_password_token }.from(nil)
    end

    it "generates a URL-safe token" do
      user.generate_password_reset_token!
      expect(user.reset_password_token).to match(/\A[A-Za-z0-9_-]+\z/)
    end

    it "sets reset_password_sent_at to current time" do
      user.generate_password_reset_token!
      expect(user.reset_password_sent_at).to be_within(1.second).of(Time.current)
    end

    it "saves without validation" do
      user.email = "" # Make invalid
      expect {
        user.generate_password_reset_token!
      }.not_to raise_error
    end

    it "generates unique tokens for different calls" do
      user.generate_password_reset_token!
      first_token = user.reset_password_token

      user.generate_password_reset_token!
      second_token = user.reset_password_token

      expect(first_token).not_to eq(second_token)
    end
  end

  describe "#password_reset_valid?" do
    let(:user) { User.create!(email: "test@example.com", password: "password123") }

    context "when reset_password_sent_at is nil" do
      it "returns false" do
        user.update_column(:reset_password_sent_at, nil)
        expect(user.password_reset_valid?).to be false
      end
    end

    context "when token was sent within 2 hours" do
      it "returns true" do
        user.update_column(:reset_password_sent_at, 1.hour.ago)
        expect(user.password_reset_valid?).to be true
      end

      it "returns true just before 2 hours" do
        user.update_column(:reset_password_sent_at, 2.hours.ago + 1.second)
        expect(user.password_reset_valid?).to be true
      end
    end

    context "when token was sent more than 2 hours ago" do
      it "returns false" do
        user.update_column(:reset_password_sent_at, 2.hours.ago - 1.second)
        expect(user.password_reset_valid?).to be false
      end

      it "returns false for much older tokens" do
        user.update_column(:reset_password_sent_at, 1.day.ago)
        expect(user.password_reset_valid?).to be false
      end
    end
  end

  describe "role functionality" do
    describe "#admin?" do
      it "returns false for regular users" do
        user = create(:user, role: "user")
        expect(user.admin?).to be false
      end

      it "returns true for admin users" do
        user = create(:user, role: "admin")
        expect(user.admin?).to be true
      end
    end

    describe "#user?" do
      it "returns true for regular users" do
        user = create(:user, role: "user")
        expect(user.user?).to be true
      end

      it "returns false for admin users" do
        user = create(:user, role: "admin")
        expect(user.user?).to be false
      end
    end

    describe "role validation" do
      it "accepts valid roles" do
        user = build(:user, role: "user")
        expect(user).to be_valid

        user.role = "admin"
        expect(user).to be_valid
      end

      it "rejects invalid roles" do
        user = build(:user, role: "invalid")
        expect(user).not_to be_valid
        expect(user.errors[:role]).to include("is not included in the list")
      end

      it "has user as default role" do
        user = User.create!(email: "test@example.com", password: "password123")
        expect(user.role).to eq("user")
      end
    end
  end
end
