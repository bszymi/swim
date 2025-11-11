require "rails_helper"

RSpec.describe MeetRule, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:meeting) }
  end

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:allow_sc_to_lc).in_array([ true, false ]) }
    it { is_expected.to validate_inclusion_of(:allow_lc_to_sc).in_array([ true, false ]) }
  end

  describe "#conversion_allowed?" do
    let(:meet_set) { Meeting.create!(name: "Test Meet") }

    context "when from and to courses are the same" do
      it "returns true" do
        rule = MeetRule.new(
          meeting: meet_set,
          allow_sc_to_lc: false,
          allow_lc_to_sc: false
        )
        expect(rule.conversion_allowed?("LC", "LC")).to be true
        expect(rule.conversion_allowed?("SC", "SC")).to be true
      end
    end

    context "when converting SC to LC" do
      it "returns true when allow_sc_to_lc is true" do
        rule = MeetRule.new(
          meeting: meet_set,
          allow_sc_to_lc: true,
          allow_lc_to_sc: false
        )
        expect(rule.conversion_allowed?("SC", "LC")).to be true
      end

      it "returns false when allow_sc_to_lc is false" do
        rule = MeetRule.new(
          meeting: meet_set,
          allow_sc_to_lc: false,
          allow_lc_to_sc: false
        )
        expect(rule.conversion_allowed?("SC", "LC")).to be false
      end
    end

    context "when converting LC to SC" do
      it "returns true when allow_lc_to_sc is true" do
        rule = MeetRule.new(
          meeting: meet_set,
          allow_lc_to_sc: true,
          allow_sc_to_lc: false
        )
        expect(rule.conversion_allowed?("LC", "SC")).to be true
      end

      it "returns false when allow_lc_to_sc is false" do
        rule = MeetRule.new(
          meeting: meet_set,
          allow_lc_to_sc: false,
          allow_sc_to_lc: false
        )
        expect(rule.conversion_allowed?("LC", "SC")).to be false
      end
    end

    context "with invalid course types" do
      it "returns false" do
        rule = MeetRule.new(
          meeting: meet_set,
          allow_sc_to_lc: true,
          allow_lc_to_sc: true
        )
        expect(rule.conversion_allowed?("INVALID", "LC")).to be false
        expect(rule.conversion_allowed?("LC", "INVALID")).to be false
      end
    end
  end

  describe "#license_level_valid?" do
    let(:meet_set) { Meeting.create!(name: "Test Meet") }

    context "when min_license_level is nil" do
      it "returns true for any level" do
        rule = MeetRule.new(
          meeting: meet_set,
          min_license_level: nil,
          allow_sc_to_lc: false,
          allow_lc_to_sc: false
        )
        expect(rule.license_level_valid?(nil)).to be true
        expect(rule.license_level_valid?(1)).to be true
        expect(rule.license_level_valid?(5)).to be true
      end
    end

    context "when min_license_level is set" do
      it "returns true when level meets or exceeds minimum" do
        rule = MeetRule.new(
          meeting: meet_set,
          min_license_level: 3,
          allow_sc_to_lc: false,
          allow_lc_to_sc: false
        )
        expect(rule.license_level_valid?(3)).to be true
        expect(rule.license_level_valid?(4)).to be true
        expect(rule.license_level_valid?(5)).to be true
      end

      it "returns false when level is below minimum" do
        rule = MeetRule.new(
          meeting: meet_set,
          min_license_level: 3,
          allow_sc_to_lc: false,
          allow_lc_to_sc: false
        )
        expect(rule.license_level_valid?(1)).to be false
        expect(rule.license_level_valid?(2)).to be false
      end

      it "returns false when level is nil" do
        rule = MeetRule.new(
          meeting: meet_set,
          min_license_level: 3,
          allow_sc_to_lc: false,
          allow_lc_to_sc: false
        )
        expect(rule.license_level_valid?(nil)).to be false
      end
    end
  end
end
