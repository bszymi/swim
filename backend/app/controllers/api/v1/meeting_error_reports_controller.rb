module Api
  module V1
    class MeetingErrorReportsController < BaseController
      before_action :set_error_report, only: [ :update ]
      before_action :require_admin!, only: [ :index, :update ]

      def index
        reports = MeetingErrorReport.includes(:meeting, :user).recent
        reports = reports.where(status: params[:status]) if params[:status].present?

        render json: reports.map { |report| error_report_json(report) }
      end

      def create
        meeting = Meeting.find(params[:meeting_id])
        error_report = current_user.error_reports.build(
          meeting: meeting,
          description: params[:description],
          status: "pending"
        )

        if error_report.save
          render json: {
            error_report: error_report_json(error_report),
            message: "Error report submitted successfully. An admin will review it soon."
          }, status: :created
        else
          render json: { errors: error_report.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @error_report.update(status: params[:status])
          render json: {
            error_report: error_report_json(@error_report),
            message: "Error report updated successfully"
          }
        else
          render json: { errors: @error_report.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def require_admin!
        return if performed?

        unless current_user&.admin?
          render json: { error: "Unauthorized. Admin access required." }, status: :forbidden
        end
      end

      def set_error_report
        @error_report = MeetingErrorReport.find(params[:id])
      end

      def error_report_json(report)
        {
          id: report.id,
          meeting_id: report.meet_standard_set_id,
          meeting_name: report.meeting.name,
          user_email: report.user.email,
          description: report.description,
          status: report.status,
          created_at: report.created_at,
          updated_at: report.updated_at
        }
      end
    end
  end
end
