require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  describe "password_reset" do
    let(:user) do
      User.create!(email: "test@example.com", password: "password123").tap do |u|
        u.generate_password_reset_token!
      end
    end
    let(:mail) { UserMailer.password_reset(user) }

    it "renders the headers" do
      expect(mail.subject).to eq("Reset Your Password - Swim Meet Manager")
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(["noreply@swimmeetmanager.com"])
    end

    it "includes user email in body" do
      expect(mail.body.encoded).to match(user.email)
    end

    it "includes reset URL with token in body" do
      expect(mail.body.encoded).to match(/reset-password\/#{user.reset_password_token}/)
    end

    it "includes FRONTEND_URL in reset link" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("FRONTEND_URL").and_return("http://example.com")

      mail = UserMailer.password_reset(user)
      expect(mail.body.encoded).to match(/http:\/\/example\.com\/reset-password/)
    end

    it "mentions 2 hour expiration" do
      expect(mail.body.encoded).to match(/2 hours/)
    end

    it "has both HTML and text parts" do
      expect(mail.body.parts.map(&:content_type)).to include(
        match(/text\/html/),
        match(/text\/plain/)
      )
    end

    describe "HTML part" do
      let(:html_part) { mail.body.parts.find { |p| p.content_type.match(/html/) } }

      it "includes reset button" do
        expect(html_part.body.encoded).to match(/Reset Password/)
      end

      it "includes styled content" do
        expect(html_part.body.encoded).to match(/background-color/)
      end
    end

    describe "text part" do
      let(:text_part) { mail.body.parts.find { |p| p.content_type.match(/plain/) } }

      it "includes reset URL" do
        expect(text_part.body.encoded).to match(/reset-password\/#{user.reset_password_token}/)
      end

      it "includes user email" do
        expect(text_part.body.encoded).to match(user.email)
      end
    end
  end
end
