class MeetingMatcher
  # Match a Meeting (from PDF) to a LiveMeeting (from scraping)
  # Uses license_number as the primary matching criterion
  #
  # @param meeting [Meeting] The meeting from PDF parsing
  # @return [LiveMeeting, nil] The matched live meeting or nil
  def self.find_live_meeting(meeting)
    # Try using the explicit license_number first
    if meeting.license_number.present?
      live_meeting = find_by_license_in_name(meeting.license_number)
      return live_meeting if live_meeting
    end

    # If no match found or no license_number set, try extracting from the meeting name
    extracted_license = extract_license_from_name(meeting.name)
    if extracted_license.present?
      live_meeting = find_by_license_in_name(extracted_license)
      return live_meeting if live_meeting
    end

    nil
  end

  # Extract license number from LiveMeeting name
  # Format: "Meet Name - 4NE252206"
  # Returns the license code (e.g., "4NE252206")
  def self.extract_license_from_name(name)
    return nil unless name.present?

    # Match pattern: Level (1 digit) + Region (2-4 letters) + Year/Sequence (6 digits)
    # Examples: 4NE252206, 3SE251839, 4WM252313
    match = name.match(/\b(\d[A-Z]{2,4}\d{6})\b/)
    match ? match[1] : nil
  end

  private_class_method def self.find_by_license_in_name(license_number)
    return nil unless license_number.present?

    # Try exact match in meet_number field first
    live_meeting = LiveMeeting.find_by(meet_number: license_number)
    return live_meeting if live_meeting

    # Try finding it in the name (e.g., "... - 4NE252206")
    LiveMeeting.where("name LIKE ?", "%#{license_number}%").first
  end
end
