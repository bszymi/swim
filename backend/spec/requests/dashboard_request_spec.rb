require "rails_helper"

RSpec.describe "Dashboards", type: :request do
  let(:user) { User.create!(email: "test@example.com", password: "password123") }

  describe "GET /dashboard" do
    context "when not authenticated" do
      it "redirects to sign in" do
        get dashboard_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "returns http success" do
        get dashboard_path
        expect(response).to have_http_status(:success)
      end

      it "loads swimmers, meetings, and recent performances" do
        swimmer = Swimmer.create!(first_name: "John", last_name: "Doe", dob: Date.new(2010, 1, 1), sex: "M")
        user.swimmers << swimmer
        meeting = Meeting.create!(name: "Test Meet")
        performance = Performance.create!(
          swimmer: swimmer,
          stroke: "FREE",
          distance_m: 100,
          course_type: "LC",
          time_seconds: 60.0,
          date: Date.today
        )

        get dashboard_path
        expect(response).to have_http_status(:success)
        expect(assigns(:swimmers)).to include(swimmer)
        expect(assigns(:meetings)).to include(meeting)
        expect(assigns(:recent_performances)).to include(performance)
      end

      it "calculates correct stats" do
        3.times do |i|
          swimmer = Swimmer.create!(
            first_name: "Swimmer#{i}",
            last_name: "Test",
            dob: Date.new(2010, 1, 1),
            sex: "M"
          )
          user.swimmers << swimmer
          Performance.create!(
            swimmer: swimmer,
            stroke: "FREE",
            distance_m: 100,
            course_type: "LC",
            time_seconds: 60.0,
            date: Date.today
          )
        end

        Meeting.create!(name: "Meet 1")
        Meeting.create!(name: "Meet 2")

        get dashboard_path
        expect(assigns(:stats)[:total_swimmers]).to eq(3)
        expect(assigns(:stats)[:total_performances]).to eq(3)
        expect(assigns(:stats)[:total_meets]).to eq(2)
      end

      it "limits recent performances to 10" do
        swimmer = Swimmer.create!(first_name: "John", last_name: "Doe", dob: Date.new(2010, 1, 1), sex: "M")
        user.swimmers << swimmer

        15.times do |i|
          Performance.create!(
            swimmer: swimmer,
            stroke: "FREE",
            distance_m: 100,
            course_type: "LC",
            time_seconds: 60.0 + i,
            date: Date.today - i.days
          )
        end

        get dashboard_path
        expect(assigns(:recent_performances).count).to eq(10)
      end
    end
  end

  describe "GET /" do
    context "when not authenticated" do
      it "redirects to sign in" do
        get root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "routes to dashboard#index" do
        get root_path
        expect(response).to have_http_status(:success)
      end
    end
  end
end
