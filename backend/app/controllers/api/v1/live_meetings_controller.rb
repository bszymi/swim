module Api
  module V1
    class LiveMeetingsController < BaseController
      skip_before_action :authenticate_user!, only: [:index, :show, :today]

      def index
        meetings = LiveMeeting.upcoming.includes(:region, :county)

        # Filter by region if provided
        meetings = meetings.by_region(params[:region_id]) if params[:region_id].present?

        # Filter by date range
        if params[:start_date].present?
          meetings = meetings.where("start_date >= ?", params[:start_date])
        end

        if params[:end_date].present?
          meetings = meetings.where("start_date <= ?", params[:end_date])
        end

        # Filter by course type
        if params[:course_type].present?
          meetings = meetings.where(course_type: params[:course_type])
        end

        # Filter by license level
        if params[:license_level].present?
          meetings = meetings.where(license_level: params[:license_level])
        end

        render json: meetings, include: [:region, :county]
      end

      def show
        meeting = LiveMeeting.includes(:region, :county).find(params[:id])
        render json: meeting, include: [:region, :county]
      end

      def today
        meetings = LiveMeeting.today.includes(:region, :county).order(:name)
        render json: {
          date: Date.current,
          count: meetings.count,
          meetings: meetings.as_json(include: [:region, :county])
        }
      end

      def scrape
        # Get date range from params, default to next 7 days
        start_date = params[:start_date]&.to_date || Date.current
        end_date = params[:end_date]&.to_date || (Date.current + 7.days)

        begin
          scraper = SwimmingResultsMeetingScraper.new
          new_meetings = scraper.scrape_meetings(start_date, end_date)

          render json: {
            success: true,
            message: "Scraped #{new_meetings.count} meetings",
            meetings: new_meetings
          }, status: :created
        rescue StandardError => e
          render_error("Scraping failed: #{e.message}", :internal_server_error)
        end
      end

      def refresh
        # Refresh upcoming meetings
        scraper = SwimmingResultsMeetingScraper.new
        updated_count = scraper.refresh_upcoming_meetings

        render json: {
          success: true,
          message: "Refreshed #{updated_count} upcoming meetings"
        }
      rescue StandardError => e
        render_error("Refresh failed: #{e.message}", :internal_server_error)
      end
    end
  end
end
