require "rails_helper"

RSpec.describe MeetingErrorReport, type: :model do
  describe "associations" do
    it { should belong_to(:meeting).class_name("Meeting").with_foreign_key("meet_standard_set_id") }
    it { should belong_to(:user) }
  end

  describe "validations" do
    it { should validate_presence_of(:description) }
    it { should validate_length_of(:description).is_at_least(10).is_at_most(1000) }
    it { should validate_inclusion_of(:status).in_array(MeetingErrorReport::STATUSES) }
  end

  describe "scopes" do
    let!(:pending_report) { create(:meeting_error_report, status: "pending") }
    let!(:resolved_report) { create(:meeting_error_report, status: "resolved") }

    it "filters pending reports" do
      expect(MeetingErrorReport.pending).to include(pending_report)
      expect(MeetingErrorReport.pending).not_to include(resolved_report)
    end

    it "filters resolved reports" do
      expect(MeetingErrorReport.resolved).to include(resolved_report)
      expect(MeetingErrorReport.resolved).not_to include(pending_report)
    end

    it "orders by recent first" do
      older_report = create(:meeting_error_report, created_at: 2.days.ago)
      newer_report = create(:meeting_error_report, created_at: 1.day.ago)

      recent = MeetingErrorReport.where(id: [ older_report.id, newer_report.id ]).recent
      expect(recent.first).to eq(newer_report)
      expect(recent.last).to eq(older_report)
    end
  end

  describe "#pending?" do
    it "returns true for pending reports" do
      report = build(:meeting_error_report, status: "pending")
      expect(report.pending?).to be true
    end

    it "returns false for resolved reports" do
      report = build(:meeting_error_report, status: "resolved")
      expect(report.pending?).to be false
    end
  end

  describe "#resolved?" do
    it "returns true for resolved reports" do
      report = build(:meeting_error_report, status: "resolved")
      expect(report.resolved?).to be true
    end

    it "returns false for pending reports" do
      report = build(:meeting_error_report, status: "pending")
      expect(report.resolved?).to be false
    end
  end

  describe "#mark_as_resolved!" do
    it "updates status to resolved" do
      report = create(:meeting_error_report, status: "pending")
      report.mark_as_resolved!

      expect(report.reload.status).to eq("resolved")
    end
  end
end
