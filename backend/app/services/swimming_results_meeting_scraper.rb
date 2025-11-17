require "nokogiri"
require "httpx"

class SwimmingResultsMeetingScraper
  BASE_URL = "https://www.swimmingresults.org"

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

  # Scrape all upcoming meetings from licensed_meets page
  # @param date [Date] The date to scrape (unused, kept for API compatibility)
  # @return [Array<LiveMeeting>] Array of meetings
  def scrape_meetings_for_date(date)
    url = "#{BASE_URL}/licensed_meets/"

    response = @session.get(url)

    unless response.status == 200
      raise ScraperError, "Failed to fetch data: HTTP #{response.status}"
    end

    doc = Nokogiri::HTML(response.body)

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

    # Get all table rows, skip the header row
    meeting_rows = doc.css("table tr")[1..-1]

    meeting_rows.each do |row|
      meeting_data = extract_meeting_data(row)
      next unless meeting_data

      meeting = create_or_update_meeting(meeting_data)
      meetings << meeting if meeting
    end

    meetings
  end

  def extract_meeting_data(row)
    cells = row.css("td")
    return nil if cells.empty? || cells.count < 4

    begin
      # Cell 0: Date (e.g., "18thNov 2025  ")
      date_text = cells[0].text.strip
      start_date = parse_date(date_text)
      return nil unless start_date

      # Cell 1: Name with link and meet number
      name_cell = cells[1]
      name = name_cell.text.strip
      link = name_cell.css("a").first
      meet_number = extract_meet_number(name, link)

      # Check if meeting already exists - skip parsing details if it does
      existing = if meet_number.present?
        LiveMeeting.exists?(meet_number: meet_number)
      else
        LiveMeeting.exists?(name: name, start_date: start_date)
      end

      if existing
        Rails.logger.debug("Skipping existing meeting: #{name}")
        return nil
      end

      # Cell 2: Country (usually just an image, can skip)

      # Cell 3: Details (e.g., "North East RegionShort CourseLevel 4Club")
      details_text = cells[3].text.strip
      details = parse_details(details_text)

      {
        meet_number: meet_number,
        name: name,
        region_name: details[:region],
        course_type: details[:course_type],
        license_level: details[:license_level],
        event_type: details[:event_type],
        start_date: start_date,
        external_url: extract_url(link)
      }
    rescue => e
      Rails.logger.warn("Failed to extract meeting data: #{e.message}")
      nil
    end
  end

  def extract_url(link)
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

  def parse_date(date_text)
    # Parse "18thNov 2025" format
    # Remove ordinal suffixes (st, nd, rd, th)
    cleaned = date_text.gsub(/(\d+)(st|nd|rd|th)/, '\1')
    Date.parse(cleaned)
  rescue ArgumentError => e
    Rails.logger.warn("Failed to parse date '#{date_text}': #{e.message}")
    nil
  end

  def extract_meet_number(name, link)
    # Try to extract from link first (meet.php?meet=85856)
    if link && link["href"] =~ /meet=(\d+)/
      return $1
    end

    # Try to extract from name (e.g., "Darlington ASC Club Gala 4 2025 - 4NE252206")
    if name =~ /-\s*(\w+)$/
      return $1.strip
    end

    nil
  end

  def parse_details(text)
    # Parse "North East RegionShort CourseLevel 4Club" or similar
    region = nil
    course_type = nil
    license_level = nil
    event_type = nil

    # Extract region (matches our seeded regions)
    if text =~ /(East Midlands|East|London|North East|North West|South East|South West|West Midlands)\s*Region/i
      region = $1
    end

    # Extract course type
    if text =~ /(Short Course|Long Course)/i
      course_type = $1 =~ /Short/i ? "25" : "50"
    end

    # Extract license level
    if text =~ /Level\s*(\d+)/i
      license_level = $1.to_i
    end

    # Extract event type (Club, Club Champs, etc.)
    if text =~ /(Club Champs|Club|County|Regional|National)/i
      event_type = $1
    end

    {
      region: region,
      course_type: course_type,
      license_level: license_level,
      event_type: event_type
    }
  end

  def create_or_update_meeting(data)
    return nil unless data[:name].present?

    # Find region by name
    region = find_or_create_region(data[:region_name]) if data[:region_name].present?

    # Find county by name within region
    county = find_or_create_county(data[:county_name], region) if data[:county_name].present? && region

    # Create new meeting (we already checked it doesn't exist in extract_meeting_data)
    meeting = LiveMeeting.new(
      meet_number: data[:meet_number],
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
      Rails.logger.info("Created meeting: #{meeting.name} on #{meeting.start_date}")
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
