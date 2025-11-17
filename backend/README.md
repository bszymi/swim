# Swim Qualifying Times Checker - Backend

Rails 8.1 API backend for the Swim Qualifying Times Checker application.

## Overview

This application helps swimmers and coaches:
- Upload and parse PDF meet qualifying times documents using Claude AI
- Check swimmer times against meet qualification standards
- Track swimmer performances and progress
- Discover upcoming swimming meets from SwimmingResults.org
- Automatically link qualifying documents with live meet data

## Tech Stack

- Ruby 3.4.2
- Rails 8.1
- PostgreSQL
- Docker & Docker Compose
- Claude AI (Anthropic) for PDF parsing
- RSpec for testing
- Devise for authentication

## Getting Started

### Prerequisites
- Docker and Docker Compose
- Ruby 3.4.2 (if running locally)
- PostgreSQL (if running locally)

### Setup with Docker

1. Clone the repository
2. Set up environment variables:
   ```bash
   cp .env.example .env
   # Add your ANTHROPIC_API_KEY
   ```

3. Build and start services:
   ```bash
   docker compose up
   ```

4. Create and seed database:
   ```bash
   docker compose exec backend bin/rails db:create db:migrate db:seed
   ```

5. The API will be available at http://localhost:3000

### Running Tests

```bash
# All tests
docker compose exec backend bundle exec rspec

# Specific test file
docker compose exec backend bundle exec rspec spec/models/swimmer_spec.rb

# With coverage
docker compose exec backend bundle exec rspec --format documentation
```

### Linting

```bash
# Check for issues
docker compose exec backend bundle exec rubocop

# Auto-fix issues
docker compose exec backend bundle exec rubocop -A
```

## Features

### PDF Parsing
Upload PDF meet qualifying times documents and automatically extract:
- Meet name and details
- Qualification standards by event, age group, and gender
- Pool type requirements (LC/SC)
- Age calculation rules

See: `app/services/meet_parser.rb`

### Live Meetings
Scrape and access upcoming swimming meets from SwimmingResults.org:
- Automatic scraping from licensed meets page
- Filter by region, date, course type, license level
- Automatic linking to parsed PDF documents via license numbers

**Documentation:** [doc/live_meetings.md](doc/live_meetings.md)

### Meeting Matching
Intelligent matching between parsed PDFs and live meets using Swim England license numbers:
- Extracts license numbers from PDFs (e.g., "4NE252206")
- Multiple matching strategies (exact, name search, extraction)
- Automatic linking during PDF confirmation

See: `app/services/meeting_matcher.rb`

### Swimmers & Performances
- Add swimmers with Swim England membership IDs
- Track performances across multiple events
- Calculate qualifying status for meets
- View progress over time

### User Management
- Devise authentication with JWT tokens
- Password reset functionality
- User can manage multiple swimmers
- OAuth support (optional)

## API Documentation

### Authentication Endpoints
- `POST /api/v1/users/sign_in` - Login
- `POST /api/v1/users/sign_up` - Register
- `POST /api/v1/users/password` - Request password reset
- `PUT /api/v1/users/password` - Reset password with token

### Live Meetings Endpoints
- `GET /api/v1/live_meetings` - List upcoming meets (with filters)
- `GET /api/v1/live_meetings/:id` - Get meet details
- `GET /api/v1/live_meetings/today` - Today's meets
- `POST /api/v1/live_meetings/scrape` - Scrape new meets (authenticated)

### Regions Endpoints
- `GET /api/v1/regions` - List all Swim England regions
- `GET /api/v1/regions/:id` - Get region with counties
- `GET /api/v1/regions/:id/counties` - List counties in region

### Swimmers Endpoints
- `GET /api/v1/swimmers` - List user's swimmers
- `POST /api/v1/swimmers` - Add a swimmer
- `GET /api/v1/swimmers/:id` - Get swimmer details
- `PUT /api/v1/swimmers/:id` - Update swimmer

### Meetings Endpoints (Parsed PDFs)
- `GET /api/v1/meetings` - List parsed meetings
- `POST /api/v1/meetings` - Upload and parse PDF
- `GET /api/v1/meetings/:id` - Get meeting details with standards

## Database Schema

### Core Models
- **User** - Application users with authentication
- **Swimmer** - Swimmers tracked by users
- **Performance** - Individual swim times for a swimmer
- **Meeting** (MeetStandardSet) - Parsed PDF qualifying documents
- **MeetingStandard** (MeetStandardRow) - Individual qualifying times
- **LiveMeeting** - Upcoming meets from SwimmingResults.org
- **Region** - Swim England regions (8 regions)
- **County** - Counties within regions (51 total)

### Key Relationships
- Meeting `belongs_to` LiveMeeting (via license_number matching)
- LiveMeeting `belongs_to` Region
- LiveMeeting `belongs_to` County
- Swimmer `has_many` Performances
- Meeting `has_many` MeetingStandards

## Background Jobs

- `ProcessMeetResponseJob` - Process Claude AI PDF parsing response
- `ConfirmMeetingJob` - Create meeting from parsed data and auto-link to LiveMeeting

## Services

- **MeetParser** - Parse PDF with Claude AI
- **SwimmingResultsMeetingScraper** - Scrape meets from SwimmingResults.org
- **MeetingMatcher** - Match parsed PDFs to live meets by license number

## Seeded Data

The application seeds:
- 8 Swim England regions with official 2024-2025 structure
- 51 counties across all regions

Run seeds with:
```bash
docker compose exec backend bin/rails db:seed
```

## Environment Variables

Required:
- `ANTHROPIC_API_KEY` - For Claude AI PDF parsing
- `DATABASE_URL` - PostgreSQL connection (provided by Docker)

Optional:
- `FRONTEND_URL` - CORS configuration for frontend
- OAuth credentials (if using social login)

## Contributing

1. Create a feature branch
2. Make changes with tests
3. Run linter: `bundle exec rubocop -A`
4. Run tests: `bundle exec rspec`
5. Create pull request

## Documentation

- [Live Meetings API Documentation](doc/live_meetings.md) - Detailed docs for live meetings feature
