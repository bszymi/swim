require "rails_helper"

RSpec.describe "Swimmers", type: :request do
  let(:user) { User.create!(email: "test@example.com", password: "password123") }

  describe "GET /swimmers" do
    context "when not authenticated" do
      it "redirects to sign in" do
        get swimmers_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "returns http success" do
        get swimmers_path
        expect(response).to have_http_status(:success)
      end

      it "lists all swimmers ordered by name" do
        swimmer1 = Swimmer.create!(first_name: "Zoe", last_name: "Adams", dob: Date.new(2010, 1, 1), sex: "F")
        swimmer2 = Swimmer.create!(first_name: "Alice", last_name: "Brown", dob: Date.new(2011, 1, 1), sex: "F")
        user.swimmers << swimmer1
        user.swimmers << swimmer2

        get swimmers_path
        expect(assigns(:swimmers)).to eq([ swimmer2, swimmer1 ])
      end

      it "includes performances association" do
        swimmer = Swimmer.create!(first_name: "John", last_name: "Doe", dob: Date.new(2010, 1, 1), sex: "M")
        user.swimmers << swimmer
        Performance.create!(
          swimmer: swimmer,
          stroke: "FREE",
          distance_m: 100,
          course_type: "LC",
          time_seconds: 60.0,
          date: Date.today
        )

        get swimmers_path
        expect(assigns(:swimmers).first.performances).to be_loaded
      end
    end
  end

  describe "GET /swimmers/new" do
    context "when not authenticated" do
      it "redirects to sign in" do
        get new_swimmer_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "returns http success" do
        get new_swimmer_path
        expect(response).to have_http_status(:success)
      end

      it "assigns a new swimmer" do
        get new_swimmer_path
        expect(assigns(:swimmer)).to be_a_new(Swimmer)
      end
    end
  end

  describe "POST /swimmers" do
    before { sign_in user }
    context "with valid parameters" do
      let(:valid_attributes) do
        {
          first_name: "John",
          last_name: "Doe",
          dob: Date.new(2010, 1, 1),
          sex: "M",
          club: "Test Club",
          se_membership_id: "12345"
        }
      end

      it "creates a new swimmer" do
        expect {
          post swimmers_path, params: { swimmer: valid_attributes }
        }.to change(Swimmer, :count).by(1)
      end

      it "associates the new swimmer with the current user" do
        post swimmers_path, params: { swimmer: valid_attributes }
        expect(user.swimmers.last.full_name).to eq("John Doe")
      end

      it "redirects to swimmers index" do
        post swimmers_path, params: { swimmer: valid_attributes }
        expect(response).to redirect_to(swimmers_path)
      end

      it "sets a success notice" do
        post swimmers_path, params: { swimmer: valid_attributes }
        follow_redirect!
        expect(response.body).to include("Swimmer added successfully!")
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) do
        {
          first_name: "",
          last_name: "",
          dob: nil,
          sex: nil
        }
      end

      it "does not create a new swimmer" do
        expect {
          post swimmers_path, params: { swimmer: invalid_attributes }
        }.not_to change(Swimmer, :count)
      end

      it "returns unprocessable entity status" do
        post swimmers_path, params: { swimmer: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /swimmers/:id" do
    before { sign_in user }

    let(:swimmer) do
      Swimmer.create!(
        first_name: "John",
        last_name: "Doe",
        dob: Date.new(2010, 1, 1),
        sex: "M"
      ).tap { |s| user.swimmers << s }
    end

    before do
      # Create multiple performances for the same event (stroke/distance/course)
      Performance.create!(
        swimmer: swimmer,
        stroke: "FREE",
        distance_m: 100,
        course_type: "LC",
        time_seconds: 60.0,
        date: Date.new(2023, 1, 1)
      )
      Performance.create!(
        swimmer: swimmer,
        stroke: "FREE",
        distance_m: 100,
        course_type: "LC",
        time_seconds: 58.5,
        date: Date.new(2023, 6, 1)
      )
      Performance.create!(
        swimmer: swimmer,
        stroke: "FREE",
        distance_m: 100,
        course_type: "SC",
        time_seconds: 57.0,
        date: Date.new(2023, 3, 1)
      )
      Performance.create!(
        swimmer: swimmer,
        stroke: "BACK",
        distance_m: 100,
        course_type: "LC",
        time_seconds: 70.0,
        date: Date.new(2023, 2, 1)
      )
    end

    it "returns http success" do
      get swimmer_path(swimmer)
      expect(response).to have_http_status(:success)
    end

    it "shows only personal bests for LC" do
      get swimmer_path(swimmer)
      lc_perfs = assigns(:lc_performances)

      # Should have 2 LC PBs (100 FREE and 100 BACK)
      expect(lc_perfs.count).to eq(2)

      # 100 FREE LC should be 58.5 (not 60.0)
      free_pb = lc_perfs.find { |p| p.stroke == "FREE" && p.distance_m == 100 }
      expect(free_pb.time_seconds).to eq(58.5)

      # 100 BACK LC should be 70.0
      back_pb = lc_perfs.find { |p| p.stroke == "BACK" && p.distance_m == 100 }
      expect(back_pb.time_seconds).to eq(70.0)
    end

    it "shows only personal bests for SC" do
      get swimmer_path(swimmer)
      sc_perfs = assigns(:sc_performances)

      # Should have 1 SC PB (100 FREE)
      expect(sc_perfs.count).to eq(1)

      # 100 FREE SC should be 57.0
      free_pb = sc_perfs.find { |p| p.stroke == "FREE" && p.distance_m == 100 }
      expect(free_pb.time_seconds).to eq(57.0)
    end
  end

  describe "GET /swimmers/:id/edit" do
    before { sign_in user }

    let(:swimmer) do
      Swimmer.create!(
        first_name: "John",
        last_name: "Doe",
        dob: Date.new(2010, 1, 1),
        sex: "M"
      ).tap { |s| user.swimmers << s }
    end

    it "returns http success" do
      get edit_swimmer_path(swimmer)
      expect(response).to have_http_status(:success)
    end

    it "assigns the swimmer" do
      get edit_swimmer_path(swimmer)
      expect(assigns(:swimmer)).to eq(swimmer)
    end
  end

  describe "PATCH /swimmers/:id" do
    before { sign_in user }

    let(:swimmer) do
      Swimmer.create!(
        first_name: "John",
        last_name: "Doe",
        dob: Date.new(2010, 1, 1),
        sex: "M"
      ).tap { |s| user.swimmers << s }
    end

    context "with valid parameters" do
      let(:new_attributes) do
        {
          first_name: "Jane",
          last_name: "Smith",
          club: "New Club"
        }
      end

      it "updates the swimmer" do
        patch swimmer_path(swimmer), params: { swimmer: new_attributes }
        swimmer.reload
        expect(swimmer.first_name).to eq("Jane")
        expect(swimmer.last_name).to eq("Smith")
        expect(swimmer.club).to eq("New Club")
      end

      it "redirects to swimmers index" do
        patch swimmer_path(swimmer), params: { swimmer: new_attributes }
        expect(response).to redirect_to(swimmers_path)
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) do
        {
          first_name: "",
          last_name: ""
        }
      end

      it "does not update the swimmer" do
        patch swimmer_path(swimmer), params: { swimmer: invalid_attributes }
        swimmer.reload
        expect(swimmer.first_name).to eq("John")
      end

      it "returns unprocessable entity status" do
        patch swimmer_path(swimmer), params: { swimmer: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /swimmers/:id" do
    before { sign_in user }

    let!(:swimmer) do
      Swimmer.create!(
        first_name: "John",
        last_name: "Doe",
        dob: Date.new(2010, 1, 1),
        sex: "M"
      ).tap { |s| user.swimmers << s }
    end

    it "destroys the swimmer" do
      expect {
        delete swimmer_path(swimmer)
      }.to change(Swimmer, :count).by(-1)
    end

    it "redirects to swimmers index" do
      delete swimmer_path(swimmer)
      expect(response).to redirect_to(swimmers_path)
    end

    it "sets a notice with swimmer name" do
      delete swimmer_path(swimmer)
      follow_redirect!
      expect(response.body).to include("John Doe has been removed")
    end
  end
end
