require "rails_helper"

RSpec.describe Swimmer, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:performances).dependent(:destroy) }
    it { is_expected.to have_many(:user_swimmers).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:user_swimmers) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:dob) }
    it { is_expected.to validate_presence_of(:sex) }
    it { is_expected.to validate_inclusion_of(:sex).in_array(%w[M F]) }

    describe "se_membership_id uniqueness" do
      it "allows nil values" do
        swimmer1 = Swimmer.create!(
          first_name: "John",
          last_name: "Doe",
          dob: Date.new(2010, 1, 1),
          sex: "M",
          se_membership_id: nil
        )
        swimmer2 = Swimmer.new(
          first_name: "Jane",
          last_name: "Doe",
          dob: Date.new(2011, 1, 1),
          sex: "F",
          se_membership_id: nil
        )
        expect(swimmer2).to be_valid
      end

      it "validates uniqueness when present" do
        Swimmer.create!(
          first_name: "John",
          last_name: "Doe",
          dob: Date.new(2010, 1, 1),
          sex: "M",
          se_membership_id: "12345"
        )
        duplicate = Swimmer.new(
          first_name: "Jane",
          last_name: "Smith",
          dob: Date.new(2011, 1, 1),
          sex: "F",
          se_membership_id: "12345"
        )
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:se_membership_id]).to include("has already been taken")
      end
    end
  end

  describe "#full_name" do
    it "returns the full name" do
      swimmer = Swimmer.new(first_name: "John", last_name: "Doe")
      expect(swimmer.full_name).to eq("John Doe")
    end
  end

  describe "#age_on" do
    let(:swimmer) { Swimmer.new(dob: Date.new(2010, 6, 15)) }

    it "calculates correct age when date is after birthday" do
      date = Date.new(2023, 7, 1)
      expect(swimmer.age_on(date)).to eq(13)
    end

    it "calculates correct age when date is before birthday" do
      date = Date.new(2023, 5, 1)
      expect(swimmer.age_on(date)).to eq(12)
    end

    it "calculates correct age on exact birthday" do
      date = Date.new(2023, 6, 15)
      expect(swimmer.age_on(date)).to eq(13)
    end

    it "handles leap year birthdays correctly" do
      leap_swimmer = Swimmer.new(dob: Date.new(2004, 2, 29))
      expect(leap_swimmer.age_on(Date.new(2023, 2, 28))).to eq(18)
      expect(leap_swimmer.age_on(Date.new(2023, 3, 1))).to eq(19)
    end
  end
end
