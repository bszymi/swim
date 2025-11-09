module Api
  module V1
    class PerformancesController < BaseController
      def import
        swimmer_id = params[:swimmer_id]

        unless swimmer_id.present?
          return render_error("Please select a swimmer", :bad_request)
        end

        swimmer = current_user.swimmers.find_by(se_membership_id: swimmer_id) ||
                  current_user.swimmers.find(swimmer_id)

        unless swimmer.se_membership_id.present?
          return render_error("Swimmer #{swimmer.full_name} does not have a Swim England membership ID", :bad_request)
        end

        historic = params[:historic] == "1" || params[:historic] == true
        ImportPerformancesJob.perform_async(swimmer.id, historic)

        message = if historic
                    "Historic import started for #{swimmer.full_name}. This will take 2-5 minutes due to rate limiting."
        else
                    "Import started for #{swimmer.full_name}. This may take a few moments."
        end

        render json: { message: message }
      end

      def history
        swimmer = current_user.swimmers.find_by!(se_membership_id: params[:id])
        stroke = params[:stroke]
        distance_m = params[:distance_m].to_i
        course_type = params[:course_type]

        performances = swimmer.performances
                              .where(stroke: stroke, distance_m: distance_m, course_type: course_type)
                              .order(date: :desc)

        personal_best = performances.min_by(&:time_seconds)

        render json: {
          swimmer: swimmer,
          performances: performances,
          personal_best: personal_best,
          stroke: stroke,
          distance_m: distance_m,
          course_type: course_type
        }
      end
    end
  end
end
