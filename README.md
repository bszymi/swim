# Swim Meet Manager

A modern swim meet qualification tracking application with AI-powered PDF parsing and automated performance imports.

## Features

- 🤖 **AI PDF Parsing** - Upload meet qualification PDFs and automatically extract standards using Claude AI
- 🏊 **Performance Tracking** - Import swimmer times from Swimming Results website
- 📊 **Visual Analytics** - Interactive charts showing performance progression over time
- ✅ **Qualification Checking** - Automatically check if swimmers meet qualification standards
- 🔄 **Auto-sync** - Automatic imports of both personal bests and historic performances
- 📱 **Responsive Design** - Works on desktop and mobile devices

## Tech Stack

### Backend
- Ruby on Rails 8.1 (API mode)
- PostgreSQL database
- Sidekiq for background jobs
- Redis for job queue
- Anthropic Claude API for PDF parsing

### Frontend
- React 18 with TypeScript
- Vite build tool
- TailwindCSS v4 for styling
- React Query for data fetching
- Recharts for visualization

## Prerequisites

- Docker and Docker Compose
- (Optional) Anthropic API key for PDF parsing

## Quick Start

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd swim
   ```

2. **Set up environment variables**
   ```bash
   cp backend/.env.example backend/.env
   ```
   
   Edit `backend/.env` and add your Anthropic API key (optional, only needed for PDF uploads):
   ```
   ANTHROPIC_API_KEY=your_api_key_here
   ```

3. **Start the application**
   ```bash
   docker compose up -d
   ```

4. **Set up the database**
   ```bash
   docker compose exec backend rails db:create db:migrate
   ```

5. **Access the application**
   - Frontend: http://localhost:5173
   - Backend API: http://localhost:3000
   - Sidekiq Web UI: http://localhost:3000/sidekiq

## Usage

### Adding Swimmers

1. Navigate to **Swimmers** → **Add Swimmer**
2. Enter swimmer details including Swimming England membership number
3. Click **Import Swimming Data** to automatically fetch their performance history

### Uploading Meeting PDFs

1. Navigate to **Meetings** → **Add Meeting**
2. Upload a PDF containing qualification standards
3. The AI will automatically parse the document and extract:
   - Meet name and season
   - Pool type (LC/SC)
   - Qualification window dates
   - All qualification standards

### Viewing Performance History

- Click on any swimmer's event to view:
  - Interactive performance graph showing progression over time
  - Full history table with dates and meet names
  - Personal best highlighted in gold

## Development

### Project Structure

```
swim/
├── backend/          # Rails API
│   ├── app/
│   │   ├── controllers/  # API endpoints
│   │   ├── jobs/        # Background jobs
│   │   ├── models/      # Database models
│   │   └── services/    # Business logic
│   └── config/
├── frontend/         # React app
│   ├── src/
│   │   ├── components/  # Reusable UI components
│   │   ├── pages/       # Page components
│   │   ├── hooks/       # Custom React hooks
│   │   └── services/    # API client
└── docker-compose.yml
```

### Running Tests

```bash
# Backend tests
docker compose exec backend rails test

# Frontend tests
docker compose exec frontend npm test
```

### Database Backup

```bash
# Create backup
docker compose exec db pg_dump -U postgres swim_development > backups/backup_$(date +%Y%m%d).sql

# Restore backup
docker compose exec -T db psql -U postgres swim_development < backups/backup_20251109.sql
```

## API Documentation

### Authentication
All API endpoints require JWT authentication except for public endpoints.

**Login**
```bash
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password"
}
```

### Swimmers
- `GET /api/v1/swimmers` - List all swimmers
- `GET /api/v1/swimmers/:se_id` - Get swimmer details
- `POST /api/v1/swimmers` - Create swimmer
- `POST /api/v1/swimmers/:se_id/import_performances` - Import times

### Meetings
- `GET /api/v1/meetings` - List all meetings
- `GET /api/v1/meetings/:id` - Get meeting details
- `POST /api/v1/meetings` - Upload meeting PDF
- `GET /api/v1/meetings/:id/compare` - Compare swimmers against standards

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_HOST` | PostgreSQL host | `db` |
| `DATABASE_PORT` | PostgreSQL port | `5432` |
| `REDIS_URL` | Redis connection URL | `redis://redis:6379/0` |
| `FRONTEND_URL` | Frontend URL for CORS | `http://localhost:5173` |
| `ANTHROPIC_API_KEY` | Claude API key for PDF parsing | - |

## Developer Documentation

For detailed development guides, see the `docs/` folder:

- **[Getting Started](docs/GETTING_STARTED.md)** - Development workflow, useful commands, styling guide, and troubleshooting

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is open source and available under the MIT License.

## Acknowledgments

- Swimming Results website for performance data
- Anthropic Claude for AI PDF parsing
- Swimming England for qualification standards
