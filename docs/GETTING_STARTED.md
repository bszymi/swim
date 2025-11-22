# Getting Started with Development

A guide for developers working on the Swim Meet Manager application.

## Project Structure

```
swim/
├── backend/              # Rails API
│   ├── app/
│   │   ├── controllers/api/v1/  # API controllers
│   │   ├── models/              # Database models
│   │   ├── services/            # Business logic services
│   │   └── jobs/                # Background jobs
│   ├── config/
│   ├── db/migrate/              # Database migrations
│   └── Dockerfile
│
├── frontend/             # React SPA
│   ├── src/
│   │   ├── components/  # Reusable UI components
│   │   ├── pages/       # Page components
│   │   ├── hooks/       # Custom React hooks
│   │   ├── services/    # API client
│   │   ├── contexts/    # React contexts
│   │   ├── types/       # TypeScript types
│   │   └── utils/       # Utility functions
│   └── Dockerfile
│
└── docker-compose.yml   # Service orchestration
```

## Starting the Application

### Prerequisites

- Docker Desktop installed and running
- Ports 3000, 5173, 5432, 6379 available

### Quick Start

```bash
# Configure environment (first time only)
cd backend && cp .env.example .env
cd ../frontend && cp .env.example .env
cd ..

# Start all services
docker compose up -d --build

# Access the app
open http://localhost:5173
```

## Development Workflow

### Docker Commands

```bash
# View logs
docker compose logs -f                    # All services
docker compose logs -f backend            # Backend only
docker compose logs -f frontend           # Frontend only
docker compose logs -f sidekiq            # Sidekiq only

# Stop services
docker compose down                       # Stop all
docker compose down -v                    # Stop and remove volumes (fresh start)

# Restart after changes
docker compose restart backend            # Restart backend
docker compose restart frontend           # Restart frontend

# Rebuild after dependency changes
docker compose up -d --build backend      # Rebuild backend
docker compose up -d --build frontend     # Rebuild frontend
```

### Backend (Rails) Commands

```bash
# Rails console
docker compose exec backend rails console

# Database operations
docker compose exec backend rails db:create
docker compose exec backend rails db:migrate
docker compose exec backend rails db:seed
docker compose exec backend rails db:reset

# Generate migrations
docker compose exec backend rails generate migration MigrationName

# View routes
docker compose exec backend rails routes | grep api

# Bundle operations
docker compose exec backend bundle install
docker compose restart backend

# Run tests
docker compose exec backend rails test
```

### Frontend (React) Commands

```bash
# Install packages
docker compose exec frontend npm install <package-name>
docker compose restart frontend

# Run commands in container
docker compose exec frontend sh

# Type checking
docker compose exec frontend npm run type-check

# Build for production
docker compose exec frontend npm run build
```

### Database Commands

```bash
# Access PostgreSQL
docker compose exec db psql -U postgres -d swim_development

# Common SQL operations
\dt                    # List tables
\d table_name          # Describe table
SELECT * FROM users;   # Query data

# Database backup
docker compose exec db pg_dump -U postgres swim_development > backups/backup_$(date +%Y%m%d).sql

# Database restore
docker compose exec -T db psql -U postgres swim_development < backups/backup_20251122.sql
```

## Styling Guide

The application uses TailwindCSS with these conventions:

### Color Palette

- **Primary**: `blue-600`, `blue-700` (buttons, links)
- **Success**: `green-500`, `green-600` (qualified swimmers)
- **Warning**: `yellow-500`, `yellow-600` (consideration times)
- **Danger**: `red-500`, `red-600` (not qualified)
- **Neutral**: `gray-50` to `gray-900` (text, backgrounds, borders)

### Common Patterns

```tsx
// Card
<div className="bg-white rounded-lg shadow-md p-6">
  {/* content */}
</div>

// Button
<button className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors">
  Click me
</button>

// Input
<input
  className="border border-gray-300 rounded-lg px-4 py-2 w-full focus:ring-2 focus:ring-blue-500 focus:border-transparent"
  type="text"
/>

// Select
<select className="border border-gray-300 rounded-lg px-4 py-2 w-full focus:ring-2 focus:ring-blue-500">
  <option>Select...</option>
</select>

// Table
<table className="min-w-full divide-y divide-gray-200">
  <thead className="bg-gray-50">
    <tr>
      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
        Header
      </th>
    </tr>
  </thead>
  <tbody className="bg-white divide-y divide-gray-200">
    <tr>
      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
        Data
      </td>
    </tr>
  </tbody>
</table>
```

## Troubleshooting

### Port Conflicts

```bash
# Check what's using a port
lsof -i :3000  # Backend
lsof -i :5173  # Frontend
lsof -i :5432  # PostgreSQL
lsof -i :6379  # Redis

# Kill process or change port in docker-compose.yml
```

### Database Connection Issues

```bash
# Wait for database to be ready
docker compose up -d db
sleep 10
docker compose up -d

# Reset everything
docker compose down -v
docker compose up -d --build
```

### Bundle/Package Issues

```bash
# Rebuild without cache
docker compose build --no-cache backend
docker compose build --no-cache frontend
docker compose up -d
```

### Changes Not Reflecting

```bash
# Backend: restart after code changes
docker compose restart backend

# Frontend: should auto-reload via Vite
# If not working:
docker compose restart frontend
```

### Docker Daemon Issues

```bash
# Ensure Docker Desktop is running
# Look for whale icon in menu bar (macOS)

# Clean up Docker resources
docker system prune -a
```

### View Container Status

```bash
# Check running containers
docker compose ps

# Check container health
docker compose logs backend | tail -50
```

## Testing

### Backend Tests

```bash
# Run all tests
docker compose exec backend rails test

# Run specific test file
docker compose exec backend rails test test/models/swimmer_test.rb

# Run with coverage
docker compose exec backend rails test
```

### Frontend Tests

```bash
# (Configure testing framework as needed)
docker compose exec frontend npm test
```

## Resources

- **Rails API**: https://guides.rubyonrails.org/api_app.html
- **React**: https://react.dev/
- **React Router**: https://reactrouter.com/
- **React Query**: https://tanstack.com/query/latest
- **TailwindCSS**: https://tailwindcss.com/docs
- **TypeScript**: https://www.typescriptlang.org/docs
- **Docker Compose**: https://docs.docker.com/compose/

## Tips for Development

### Hot Reloading

- **Frontend**: Vite provides instant hot module replacement (HMR)
- **Backend**: Restart the container after changes (`docker compose restart backend`)

### Debugging

```bash
# Backend debugging with byebug
# Add 'byebug' in your Ruby code, then:
docker compose up backend  # Run in foreground

# Frontend debugging
# Use browser DevTools and React DevTools extension
```

### Performance

- Docker volumes cache gems and node_modules for faster rebuilds
- Use `docker compose restart` instead of `down/up` when possible
- Only rebuild when dependencies change

### Code Quality

```bash
# Backend linting (if configured)
docker compose exec backend rubocop

# Frontend linting
docker compose exec frontend npm run lint
```

## Additional Documentation

- See `README.md` for architecture overview and API documentation
- Check `frontend/ARCHITECTURE.md` for component structure (if exists)
- Review commit history for implementation examples
