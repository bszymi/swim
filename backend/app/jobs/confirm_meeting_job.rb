class ConfirmMeetingJob < ApplicationJob
  queue_as :default

  def perform(parsed_meet_datum_id)
    parsed_record = ParsedMeetDatum.find(parsed_meet_datum_id)
    parsed_data = parsed_record.data

    unless parsed_data
      parsed_record.update!(
        status: "failed",
        error_message: "No parsed data found for confirmation."
      )
      return
    end

    # Check for duplicate meeting name
    existing_meeting = Meeting.find_by(name: parsed_data["meet_name"])
    if existing_meeting
      parsed_record.update!(
        status: "failed",
        error_message: "A meeting with the name '#{parsed_data["meet_name"]}' already exists."
      )
      return
    end

    begin
      # Create the meeting with license_number
      meeting = Meeting.create!(
        name: parsed_data["meet_name"],
        license_number: parsed_data["license_number"],
        season: parsed_data["season"],
        pool_required: parsed_data["pool_required"],
        window_start: parsed_data["window_start"],
        window_end: parsed_data["window_end"],
        age_rule_type: parsed_data.dig("age_calculation", "method"),
        age_rule_date: parsed_data.dig("age_calculation", "date")
      )

      # Try to match with a LiveMeeting
      live_meeting = MeetingMatcher.find_live_meeting(meeting)
      if live_meeting
        meeting.update!(live_meeting: live_meeting)
        Rails.logger.info("Matched meeting '#{meeting.name}' to live meeting '#{live_meeting.name}' (#{live_meeting.id})")
      else
        Rails.logger.info("No live meeting match found for '#{meeting.name}' with license #{meeting.license_number}")
      end

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

      # Delete the parsed record after successful confirmation
      parsed_record.destroy

      Rails.logger.info("Meeting '#{meeting.name}' auto-confirmed with #{standards_count} standards")

    rescue => e
      parsed_record.update!(
        status: "failed",
        error_message: "Failed to save meeting: #{e.message}"
      )
      Rails.logger.error("Meeting auto-confirmation failed: #{e.message}\n#{e.backtrace.join("\n")}")
      raise
    end
  end
end
