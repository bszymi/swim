module Api
  module V1
    class SwimmersController < BaseController
      before_action :set_swimmer, only: [ :show, :update, :destroy ]

      def index
        swimmers = current_user.swimmers.includes(:performances).order(:first_name, :last_name)
        render json: swimmers, include: :performances
      end

      def show
        all_performances = @swimmer.performances.order(:time_seconds)

        lc_performances = all_performances
                            .where(course_type: "LC")
                            .group_by { |p| [ p.stroke, p.distance_m ] }
                            .map { |key, perfs| perfs.min_by(&:time_seconds) }
                            .sort_by { |p| [ p.stroke, p.distance_m ] }

        sc_performances = all_performances
                            .where(course_type: "SC")
                            .group_by { |p| [ p.stroke, p.distance_m ] }
                            .map { |key, perfs| perfs.min_by(&:time_seconds) }
                            .sort_by { |p| [ p.stroke, p.distance_m ] }

        render json: {
          swimmer: @swimmer,
          lc_performances: lc_performances,
          sc_performances: sc_performances
        }
      end

      def create
        swimmer = Swimmer.new(swimmer_params)
        if swimmer.save
          current_user.swimmers << swimmer unless current_user.swimmers.include?(swimmer)
          render json: swimmer, status: :created
        else
          render_error(swimmer.errors.full_messages.join(", "))
        end
      end

      def update
        if @swimmer.update(swimmer_params)
          render json: @swimmer
        else
          render_error(@swimmer.errors.full_messages.join(", "))
        end
      end

      def destroy
        name = @swimmer.full_name
        @swimmer.destroy
        render json: { message: "#{name} has been removed." }
      end

      private

      def set_swimmer
        @swimmer = current_user.swimmers.find_by!(se_membership_id: params[:id])
      end

      def swimmer_params
        params.require(:swimmer).permit(:first_name, :last_name, :dob, :sex, :club, :se_membership_id)
      end
    end
  end
end
