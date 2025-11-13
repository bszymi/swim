require "nokogiri"
require "httpx"

class StreamingResultsMeetingScraper
  BASE_URL = "https://www.streamingresults.org" # Update this with the actual URL

  class ScraperError < StandardError; end

  def initialize
    @session = HTTPX.plugin(:follow_redirects)
  end

  # Scrape meetings for a date range
  # @param start_date [Date] The start date
  # @param end_date [Date] The end date
  # @return [Array<LiveMeeting>] Array of created/updated live meetings
  def scrape_meetings(start_date, end_date)
    Rails.logger.info("Scraping meetings from #{start_date} to #{end_date}")

    meetings = []
    current_date = start_date

    while current_date <= end_date
      begin
        daily_meetings = scrape_meetings_for_date(current_date)
        meetings.concat(daily_meetings)

        # Rate limiting - be respectful to the server
        sleep(1) unless current_date == end_date
      rescue => e
        Rails.logger.error("Error scraping meetings for #{current_date}: #{e.message}")
      end

      current_date += 1.day
    end

    Rails.logger.info("Scraped #{meetings.count} total meetings")
    meetings
  end

  # Scrape meetings for a specific date
  # @param date [Date] The date to scrape
  # @return [Array<LiveMeeting>] Array of meetings
  def scrape_meetings_for_date(date)
    # TODO: Update this URL with the actual endpoint from streamingresults.org
    # The URL should include date parameters
    url = build_date_url(date)

    response = @session.get(url)

    unless response.status == 200
      raise ScraperError, "Failed to fetch data for #{date}: HTTP #{response.status}"
    end

    doc = Nokogiri::HTML(response.body)

    # TODO: Update these selectors based on the actual HTML structure
    parse_meetings_from_html(doc, date)
  rescue HTTPX::Error => e
    raise ScraperError, "Network error: #{e.message}"
  rescue => e
    raise ScraperError, "Scraping error: #{e.message}"
  end

  # Refresh upcoming meetings (next 7 days)
  def refresh_upcoming_meetings
    start_date = Date.current
    end_date = Date.current + 7.days

    scrape_meetings(start_date, end_date)
  end

  private

  def build_date_url(date)
    # TODO: Update this with the actual URL pattern
    # Example: "#{BASE_URL}/meetings?date=#{date.strftime('%Y-%m-%d')}"
    "#{BASE_URL}/meetings?date=#{date.strftime('%Y-%m-%d')}"
  end

  def parse_meetings_from_html(doc, date)
    meetings = []

    # TODO: Update these selectors based on the actual HTML structure
    # This is a placeholder - you need to inspect the HTML to find the right selectors
    meeting_rows = doc.css("table tr.meeting-row") # Placeholder selector

    meeting_rows.each do |row|
      meeting_data = extract_meeting_data(row, date)
      next unless meeting_data

      meeting = create_or_update_meeting(meeting_data)
      meetings << meeting if meeting
    end

    meetings
  end

  def extract_meeting_data(row, date)
    # TODO: Update these selectors based on actual HTML structure
    # This is a placeholder implementation

    cells = row.css("td")
    return nil if cells.empty?

    begin
      {
        # Extract data from table cells
        # Update these indices based on actual table structure
        meet_number: cells[0]&.text&.strip,      # Meeting number/ID
        name: cells[1]&.text&.strip,              # Event name
        region_name: cells[2]&.text&.strip,       # Region
        city: cells[3]&.text&.strip,              # City/Town
        venue: cells[4]&.text&.strip,             # Venue
        course_type: parse_course_type(cells[5]&.text&.strip), # Course type (25m/50m)
        license_level: parse_license_level(cells[6]&.text&.strip), # License level
        start_date: date,
        external_url: extract_url(row)
      }
    rescue => e
      Rails.logger.warn("Failed to extract meeting data: #{e.message}")
      nil
    end
  end

  def extract_url(row)
    # Try to find a link in the row
    link = row.css("a").first
    return nil unless link

    href = link["href"]
    return nil unless href

    # Make absolute URL if it's relative
    if href.start_with?("/")
      "#{BASE_URL}#{href}"
    elsif href.start_with?("http")
      href
    else
      "#{BASE_URL}/#{href}"
    end
  end

  def parse_course_type(text)
    return nil unless text

    case text.upcase
    when /25M?/, /SHORT/, /SC/
      "25"
    when /50M?/, /LONG/, /LC/
      "50"
    else
      nil
    end
  end

  def parse_license_level(text)
    return nil unless text

    # Extract numeric license level
    match = text.match(/(\d+)/)
    match ? match[1].to_i : nil
  end

  def create_or_update_meeting(data)
    return nil unless data[:name].present?

    # Find region by name
    region = find_or_create_region(data[:region_name]) if data[:region_name].present?

    # Find county by name within region
    county = find_or_create_county(data[:county_name], region) if data[:county_name].present? && region

    # Find or create meeting by meet_number or name + date
    meeting = if data[:meet_number].present?
      LiveMeeting.find_or_initialize_by(meet_number: data[:meet_number])
    else
      LiveMeeting.find_or_initialize_by(
        name: data[:name],
        start_date: data[:start_date]
      )
    end

    # Update attributes
    meeting.assign_attributes(
      name: data[:name],
      region: region,
      county: county,
      city: data[:city],
      venue: data[:venue],
      course_type: data[:course_type] || "25", # Default to 25m
      license_level: data[:license_level],
      start_date: data[:start_date],
      external_url: data[:external_url]
    )

    if meeting.save
      Rails.logger.info("Saved meeting: #{meeting.name} on #{meeting.start_date}")
      meeting
    else
      Rails.logger.error("Failed to save meeting: #{meeting.errors.full_messages.join(', ')}")
      nil
    end
  end

  def find_or_create_region(region_name)
    return nil unless region_name.present?

    # Try to find existing region by name
    Region.find_by(name: region_name)
  end

  def find_or_create_county(county_name, region)
    return nil unless county_name.present? && region

    # Try to find existing county
    County.find_by(name: county_name, region: region)
  end
end
