# Live Meetings API

## Overview

The Live Meetings feature provides access to upcoming swimming meets scraped from [swimmingresults.org](https://www.swimmingresults.org/licensed_meets/). This data is automatically linked with parsed PDF qualifying times documents using Swim England license numbers.

## Architecture

### Models

#### LiveMeeting
Represents an upcoming swimming meet scraped from swimmingresults.org.

**Fields:**
- `name` (string, required) - Full name of the meet (e.g., "Darlington ASC Club Gala 4 2025 - 4NE252206")
- `meet_number` (string, unique) - SwimmingResults.org internal ID (e.g., "85856")
- `start_date` (date, required) - When the meet starts
- `end_date` (date, optional) - When the meet ends (if multi-day)
- `course_type` (string, required) - "25" for short course or "50" for long course
- `license_level` (integer, optional) - Swim England license level (1-4)
- `region_id` (foreign key) - Reference to Swim England region
- `county_id` (foreign key) - Reference to county within region
- `city` (string, optional) - City where meet is held
- `venue` (string, optional) - Specific venue/pool name
- `external_url` (string) - Link to meet details on swimmingresults.org
- `notes` (text, optional) - Additional notes

**Associations:**
- `belongs_to :region` (optional)
- `belongs_to :county` (optional)
- `has_many :meetings` - Linked PDF qualifying times documents

**Scopes:**
- `upcoming` - Meets from today onwards, ordered by start date
- `today` - Meets starting today
- `this_week` - Meets in the next 7 days
- `by_region(region_id)` - Filter by region

**Methods:**
- `ongoing?` - Returns true if meet is currently happening
- `course_type_display` - Returns "25m (Short Course)" or "50m (Long Course)"

#### Region
Represents a Swim England region (8 regions total).

**Fields:**
- `name` (string, unique, required) - e.g., "North East", "London"
- `code` (string, unique, required) - e.g., "NE", "LOND"
- `description` (text) - Full description

**Associations:**
- `has_many :counties`
- `has_many :live_meetings`

#### County
Represents a county within a Swim England region (51 counties total).

**Fields:**
- `name` (string, required) - e.g., "County Durham", "Greater London"
- `region_id` (foreign key, required)

**Associations:**
- `belongs_to :region`
- `has_many :live_meetings`

### API Endpoints

#### GET /api/v1/live_meetings
Returns all upcoming meetings.

**Query Parameters:**
- `region_id` (integer) - Filter by region
- `start_date` (date) - Filter by minimum start date (YYYY-MM-DD)
- `end_date` (date) - Filter by maximum start date (YYYY-MM-DD)
- `course_type` (string) - Filter by "25" or "50"
- `license_level` (integer) - Filter by license level (1-4)

**Response:**
```json
[
  {
    "id": 171,
    "name": "Darlington ASC Club Gala 4 2025 - 4NE252206",
    "meet_number": "85856",
    "region_id": 98,
    "county_id": null,
    "course_type": "25",
    "license_level": 4,
    "start_date": "2025-11-18",
    "end_date": null,
    "external_url": "https://www.swimmingresults.org/meet.php?meet=85856...",
    "region": {
      "id": 98,
      "name": "North East",
      "code": "NE"
    }
  }
]
```

#### GET /api/v1/live_meetings/:id
Returns a specific meeting with full details.

#### GET /api/v1/live_meetings/today
Returns all meetings happening today with count.

**Response:**
```json
{
  "date": "2025-11-17",
  "count": 0,
  "meetings": []
}
```

#### POST /api/v1/live_meetings/scrape
Scrapes new meetings from swimmingresults.org (requires authentication).

**Body Parameters:**
- `start_date` (optional) - Start of date range (default: today)
- `end_date` (optional) - End of date range (default: today + 7 days)

**Response:**
```json
{
  "success": true,
  "message": "Scraped 50 meetings",
  "meetings": [...]
}
```

#### GET /api/v1/regions
Returns all Swim England regions.

#### GET /api/v1/regions/:id
Returns a specific region with its counties.

#### GET /api/v1/regions/:id/counties
Returns all counties for a region.

## Scraping Service

### SwimmingResultsMeetingScraper

Service that scrapes upcoming meets from swimmingresults.org.

**Usage:**
```ruby
scraper = SwimmingResultsMeetingScraper.new
meetings = scraper.scrape_meetings(Date.current, Date.current + 30.days)
# Returns array of created LiveMeeting records
```

**Features:**
- Idempotent - won't create duplicate meetings
- Rate limiting - 1 second delay between requests
- Extracts: name, dates, region, course type, license level, meet number
- Handles errors gracefully with logging

**License Number Extraction:**
License numbers are extracted from meeting names in the format:
- Format: `{Level}{Region}{YearMonth}{Sequence}`
- Examples:
  - `4NE252206` = Level 4, North East, 2025-22 (Oct/Nov), #06
  - `3SE251839` = Level 3, South East, 2025-18 (May/Jun), #39

## Integration with PDF Meetings

### Overview
LiveMeetings are automatically linked to parsed PDF qualifying times documents (`Meeting` model) using Swim England license numbers.

### Meeting Model (PDF Parsed Data)
Located in `meet_standard_sets` table.

**Additional Fields:**
- `license_number` (string, indexed) - Extracted from PDF
- `live_meeting_id` (foreign key) - Link to LiveMeeting

**Association:**
- `belongs_to :live_meeting` (optional)

### MeetingMatcher Service

Service that matches PDF meetings to live meetings.

**Usage:**
```ruby
meeting = Meeting.find(123)
live_meeting = MeetingMatcher.find_live_meeting(meeting)

if live_meeting
  meeting.update!(live_meeting: live_meeting)
end
```

**Matching Strategies (in order):**

1. **Exact meet_number match**
   - Matches `meeting.license_number` to `live_meeting.meet_number`
   - Most reliable when license number is the internal ID

2. **License in LiveMeeting name**
   - Searches for `meeting.license_number` within `live_meeting.name`
   - Example: "Darlington ASC Club Gala 4 2025 - 4NE252206"

3. **Extract from Meeting name**
   - If no explicit license_number, extracts from meeting name
   - Uses regex: `/\b(\d[A-Z]{2,4}\d{6})\b/`
   - Handles cases where PDF parser missed it

**Methods:**
- `MeetingMatcher.find_live_meeting(meeting)` - Find matching LiveMeeting
- `MeetingMatcher.extract_license_from_name(name)` - Extract license number from name string

### Automatic Linking

When a PDF is parsed and confirmed via `ConfirmMeetingJob`, the system:

1. Creates the `Meeting` record with `license_number` from PDF
2. Calls `MeetingMatcher.find_live_meeting(meeting)`
3. If match found, updates `meeting.live_meeting = live_meeting`
4. Logs success/failure for debugging

**Benefits:**
- Get region/county data from LiveMeeting
- Access meet dates and venue information
- Link to external SwimmingResults.org page
- Enrich qualifying times with meet metadata

## Data Sources

### Swim England Regions (Seeded)
- East (EAST) - 6 counties
- East Midlands (EMID) - 5 counties
- London (LOND) - 1 county
- North East (NE) - 6 counties
- North West (NW) - 3 counties
- South East (SE) - 10 counties
- South West (SW) - 6 counties
- West Midlands (WMID) - 4 counties

Total: 8 regions, 51 counties (2024-2025 structure)

### SwimmingResults.org
- Source: https://www.swimmingresults.org/licensed_meets/
- Updates: New meets added regularly
- Covers: All licensed Swim England meets

## Testing

### Running Tests
```bash
# All live meeting tests
docker compose exec backend bundle exec rspec spec/models/live_meeting_spec.rb
docker compose exec backend bundle exec rspec spec/requests/live_meetings_request_spec.rb

# Meeting matcher tests
docker compose exec backend bundle exec rspec spec/services/meeting_matcher_spec.rb

# All specs
docker compose exec backend bundle exec rspec
```

### Test Coverage
- **LiveMeeting model**: 29 specs (validations, scopes, methods)
- **Region model**: 8 specs
- **County model**: 7 specs
- **API endpoints**: 24 specs (index, show, today, filtering)
- **MeetingMatcher**: 10 specs (all matching strategies)

## Examples

### Scrape Upcoming Meets
```ruby
# Via console
scraper = SwimmingResultsMeetingScraper.new
meetings = scraper.refresh_upcoming_meetings
puts "Scraped #{meetings.count} meetings"

# Via API (requires authentication)
curl -X POST http://localhost:3000/api/v1/live_meetings/scrape \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"start_date": "2025-11-18", "end_date": "2025-12-18"}'
```

### Query Live Meetings
```ruby
# All upcoming North East meets
LiveMeeting.upcoming.by_region(Region.find_by(code: "NE").id)

# All 25m meets this week
LiveMeeting.this_week.where(course_type: "25")

# Meets with linked qualification docs
LiveMeeting.includes(:meetings).where.not(meetings: { id: nil })
```

### Match PDF to Live Meeting
```ruby
# After parsing a PDF
meeting = Meeting.last
live_meeting = MeetingMatcher.find_live_meeting(meeting)

if live_meeting
  puts "Matched to: #{live_meeting.name}"
  puts "Region: #{live_meeting.region.name}"
  puts "Date: #{live_meeting.start_date}"
  puts "URL: #{live_meeting.external_url}"
else
  puts "No match found for license: #{meeting.license_number}"
end
```

### Via API
```bash
# Get today's meets
curl http://localhost:3000/api/v1/live_meetings/today | jq .

# Get North East meets
curl "http://localhost:3000/api/v1/live_meetings?region_id=98" | jq .

# Get meets on specific date
curl "http://localhost:3000/api/v1/live_meetings?start_date=2025-11-18&end_date=2025-11-18" | jq .

# Get all regions
curl http://localhost:3000/api/v1/regions | jq .
```

## Future Enhancements

Potential improvements:
- Schedule automatic daily scraping via Sidekiq/cron
- Add meet result scraping after meets conclude
- Extract more details from meet detail pages
- Add notifications for new meets in user's region
- Display linked live meeting data on Meeting show page
- Fuzzy name matching as fallback when license number missing
- Historical meet data and archiving
