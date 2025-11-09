module Api
  module V1
    class MeetingsController < BaseController
      before_action :set_meeting, only: [ :show, :destroy, :swimmer_time_history, :download_pdf, :compare ]

      def index
        meetings = Meeting.all.order(created_at: :desc)
        render json: meetings
      end

      def show
        all_standards = @meeting.meeting_standards.order(:gender, :stroke, :distance_m, :age_min)
        standards_by_gender = all_standards.group_by(&:gender)

        standards_matrix = {}
        standards_by_gender.each do |gender, standards|
          ages = standards.map { |s| s.age_group }.uniq.sort_by { |age| age.to_i }
          by_event = standards.group_by { |s| { stroke: s.stroke, distance: s.distance_m, course: s.course_type } }

          standards_matrix[gender] = {
            ages: ages,
            events: by_event.map do |event_key, event_standards|
              {
                stroke: event_key[:stroke],
                distance: event_key[:distance],
                course: event_key[:course],
                times_by_age: event_standards.each_with_object({}) do |standard, hash|
                  hash[standard.age_group] = {
                    age_group: standard.age_group,
                    qualifying_time: standard.qualifying_time,
                    qualifying_time_seconds: standard.qualifying_time_seconds,
                    age_min: standard.age_min,
                    age_max: standard.age_max
                  }
                end
              }
            end.sort_by { |e| [ e[:stroke], e[:distance] ] }
          }
        end

        render json: {
          meeting: @meeting,
          standards_matrix: standards_matrix
        }
      end

      def create
        unless params[:pdf_file].present?
          return render_error("Please select a PDF file to upload.", :bad_request)
        end

        pdf_file = params[:pdf_file]

        unless pdf_file.content_type == "application/pdf"
          return render_error("Please upload a valid PDF file.", :bad_request)
        end

        pdf_data = pdf_file.read

        parsed_record = ParsedMeetDatum.create!(
          status: "pending",
          data: {},
          pdf_filename: pdf_file.original_filename,
          pdf_content_type: pdf_file.content_type
        )

        parsed_record.update!(pdf_data: pdf_data.force_encoding("BINARY"))
        ParseMeetPdfJob.perform_later(parsed_record.id, pdf_data)

        render json: {
          message: "PDF uploaded successfully! Parsing in progress...",
          parsed_record_id: parsed_record.id
        }, status: :created

      rescue => e
        Rails.logger.error("Meet upload error: #{e.message}\n#{e.backtrace.join("\n")}")
        render_error("An unexpected error occurred while uploading the PDF.", :internal_server_error)
      end

      def status
        parsed_record = ParsedMeetDatum.find(params[:id])
        render json: {
          status: parsed_record.status,
          error_message: parsed_record.error_message
        }
      end

      def review
        parsed_record = ParsedMeetDatum.find(params[:id])
        render json: {
          status: parsed_record.status,
          data: parsed_record.data,
          error_message: parsed_record.error_message
        }
      end

      def confirm
        parsed_record = ParsedMeetDatum.find(params[:id])
        parsed_data = parsed_record.data

        unless parsed_data
          return render_error("No parsed data found.", :bad_request)
        end

        # Create the meeting
        meeting = Meeting.create!(
          name: parsed_data["meet_name"],
          season: parsed_data["season"],
          pool_required: parsed_data["pool_required"],
          window_start: parsed_data["window_start"],
          window_end: parsed_data["window_end"],
          age_rule_type: parsed_data.dig("age_calculation", "method"),
          age_rule_date: parsed_data.dig("age_calculation", "date")
        )

        # Attach the original PDF document if available
        if parsed_record.pdf_data.present?
          meeting.pdf_document.attach(
            io: StringIO.new(parsed_record.pdf_data),
            filename: parsed_record.pdf_filename || "meeting_document.pdf",
            content_type: parsed_record.pdf_content_type || "application/pdf"
          )
        end

        # Create all standards
        standards_count = 0
        parsed_data["standards"].each do |standard|
          age_min = nil
          age_max = nil
          if standard["age_group"] && standard["age_group"] != "Open"
            age_group_str = standard["age_group"].to_s.strip
            if age_group_str.include?("-")
              age_parts = age_group_str.split("-")
              age_min = age_parts[0].to_i
              age_max = age_parts[1].to_i
            elsif age_group_str.include?("+")
              age_min = age_group_str.gsub("+", "").to_i
            elsif age_group_str.match?(/^\d+$/)
              age = age_group_str.to_i
              age_min = age
              age_max = age
            end
          end

          meeting.meeting_standards.create!(
            distance_m: standard["distance_m"],
            stroke: standard["stroke"],
            pool_of_standard: standard["course_type"],
            age_min: age_min,
            age_max: age_max,
            gender: standard["sex"],
            standard_type: "QUALIFY",
            time_seconds: standard["qualifying_time_seconds"]
          )
          standards_count += 1
        end

        parsed_record.destroy

        render json: {
          meeting: meeting,
          message: "Meet standards imported successfully! #{standards_count} standards added."
        }, status: :created

      rescue => e
        Rails.logger.error("Meet creation error: #{e.message}\n#{e.backtrace.join("\n")}")
        render_error("Failed to save meet standards: #{e.message}", :internal_server_error)
      end

      def compare
        swimmers = current_user.swimmers.order(:last_name, :first_name)

        selected_swimmer_ids = if params[:swimmer_ids].present?
                                  params[:swimmer_ids]
        else
                                  swimmers.pluck(:id).map(&:to_s)
        end

        if selected_swimmer_ids.any?
          selected_swimmers = current_user.swimmers.where(id: selected_swimmer_ids).order(:last_name, :first_name)
          all_standards = @meeting.meeting_standards.order(:gender, :stroke, :distance_m, :age_min)

          comparison_data = {}

          [ "M", "F" ].each do |gender|
            gender_swimmers = selected_swimmers.select { |s| s.sex == gender }
            next if gender_swimmers.empty?

            gender_standards = all_standards.select { |s| s.gender == gender }
            ages = gender_standards.map { |s| s.age_group }.uniq.sort_by { |age| age.to_i }
            by_event = gender_standards.group_by { |s| { stroke: s.stroke, distance: s.distance_m, course: s.course_type } }

            events_data = by_event.map do |event_key, event_standards|
              swimmer_data = gender_swimmers.map do |swimmer|
                perf_query = swimmer.performances
                  .where(stroke: event_key[:stroke], distance_m: event_key[:distance])

                perf_query = perf_query.where("date <= ?", @meeting.window_end) if @meeting.window_end.present?

                best_perf = perf_query.order(:time_seconds).first

                swimmer_time = nil
                if best_perf
                  swimmer_time = if @meeting.pool_required == "LC"
                    best_perf.lc_time_seconds || best_perf.time_seconds
                  else
                    best_perf.sc_time_seconds || best_perf.time_seconds
                  end
                end

                swimmer_age = swimmer.age_on(@meeting.age_reference_date)
                required_time_row = event_standards.find { |s| s.applies_to_age?(swimmer_age) }
                required_time = required_time_row&.qualifying_time_seconds
                qualifies = required_time && swimmer_time && swimmer_time <= required_time

                {
                  swimmer: swimmer,
                  age: swimmer_age,
                  time_seconds: swimmer_time,
                  time_formatted: swimmer_time ? TimeParser.to_formatted(swimmer_time) : nil,
                  qualifies: qualifies,
                  required_time: required_time,
                  time_difference: (swimmer_time && required_time) ? (swimmer_time - required_time) : nil,
                  original_course: best_perf&.course_type,
                  converted: best_perf&.course_type != @meeting.pool_required
                }
              end

              {
                stroke: event_key[:stroke],
                distance: event_key[:distance],
                course: event_key[:course],
                times_by_age: event_standards.index_by(&:age_group),
                swimmer_data: swimmer_data
              }
            end.sort_by { |e| [ e[:stroke], e[:distance] ] }

            comparison_data[gender] = {
              ages: ages,
              swimmers: gender_swimmers,
              events: events_data
            }
          end

          render json: {
            meeting: @meeting,
            swimmers: swimmers,
            selected_swimmer_ids: selected_swimmer_ids,
            comparison_data: comparison_data
          }
        else
          render json: {
            meeting: @meeting,
            swimmers: swimmers,
            selected_swimmer_ids: [],
            comparison_data: {}
          }
        end
      end

      def swimmer_time_history
        swimmer = current_user.swimmers.find(params[:swimmer_id])
        stroke = params[:stroke]
        distance_m = params[:distance_m].to_i

        performances = swimmer.performances
          .where(stroke: stroke, distance_m: distance_m)
          .order(date: :desc)

        history = performances.map do |perf|
          {
            date: perf.date.strftime("%d %b %Y"),
            meet_name: perf.meet_name,
            course_type: perf.course_type,
            time_seconds: perf.time_seconds,
            time_formatted: perf.time_formatted,
            lc_time_seconds: perf.lc_time_seconds,
            lc_time_formatted: perf.lc_time_seconds ? TimeParser.to_formatted(perf.lc_time_seconds) : nil,
            sc_time_seconds: perf.sc_time_seconds,
            sc_time_formatted: perf.sc_time_seconds ? TimeParser.to_formatted(perf.sc_time_seconds) : nil
          }
        end

        render json: {
          swimmer_name: swimmer.full_name,
          event: "#{distance_m}m #{stroke}",
          history: history
        }
      end

      def download_pdf
        # PDF download logic
        send_data @meeting.pdf_document.download,
                  filename: @meeting.pdf_document.filename.to_s,
                  type: "application/pdf",
                  disposition: "attachment"
      end

      def destroy
        name = @meeting.name
        @meeting.destroy
        render json: { message: "#{name} has been removed." }
      end

      private

      def set_meeting
        @meeting = Meeting.find(params[:id])
      end
    end
  end
end
