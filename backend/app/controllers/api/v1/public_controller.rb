module Api
  module V1
    class PublicController < ApplicationController
      skip_before_action :authenticate_user!, only: [ :check_qualification ]

      def check_qualification
        dob = Date.parse(params[:dob]) rescue nil
        sex = params[:sex]
        stroke = params[:stroke]
        distance_m = params[:distance_m].to_i
        time_str = params[:time]
        course_type = params[:course_type]

        if dob.nil? || sex.blank? || stroke.blank? || distance_m.zero? || time_str.blank? || course_type.blank?
          return render json: { error: "Please fill in all required fields." }, status: :bad_request
        end

        time_seconds = TimeParser.to_seconds(time_str, distance_m: distance_m)
        if time_seconds.nil?
          return render json: { error: "Invalid time format. Please use MM:SS.SS or SS.SS format." }, status: :bad_request
        end

        checker = PublicQualificationChecker.new(
          dob: dob,
          sex: sex,
          stroke: stroke,
          distance_m: distance_m,
          time_seconds: time_seconds,
          course_type: course_type
        )

        results = checker.check_all_meets

        render json: { results: results }

      rescue StandardError => e
        Rails.logger.error("Error checking qualification: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        render json: { error: "An error occurred while checking qualification. Please try again." }, status: :internal_server_error
      end
    end
  end
end
