# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a comprehensive Left 4 Dead 2 statistics tracking system consisting of:
- **SourceMod Plugins**: Two .sp files that run on the L4D2 server to track gameplay statistics
- **Website API**: Node.js Express server that provides REST endpoints for statistics data
- **Website UI**: Vue.js frontend for displaying player statistics and game data
- **Database**: MariaDB/MySQL database for storing all game statistics

## Architecture

### Core Components

1. **SourceMod Plugins** (`/scripting/`):
   - `l4d2_stats_recorder.sp`: Main plugin that records gameplay statistics to database
   - `l4d2_skill_detect.sp`: Detects and reports skill-based actions (skeets, crowns, levels, etc.)
   - Compiled plugins (`.smx`) are stored in `/plugins/`

2. **Website API** (`/website-api/`):
   - Node.js Express server with MySQL2 database connection
   - Routes in `/routes/` for different data endpoints (campaigns, maps, sessions, users, etc.)
   - Uses Canvas library for dynamic image generation

3. **Website UI** (`/website-ui/`):
   - Vue.js 2 application with Buefy component library
   - Vue Router for page navigation
   - Chart.js for statistics visualization
   - FontAwesome icons

4. **Database**:
   - MariaDB 10.7+ required for UUID support
   - Schema defined in `stats_database.sql`
   - Various maintenance and fix scripts provided

## Development Commands

### Website API
```bash
cd website-api
yarn install
yarn dev        # Development with nodemon
yarn start      # Production
```

### Website UI
```bash
cd website-ui
yarn install
yarn serve      # Development server with hot-reload
yarn build      # Production build
yarn lint       # ESLint with auto-fix
```

### Docker Development
```bash
# Start all services (MariaDB, API, UI, phpMyAdmin)
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs [service-name]

# Stop services
docker-compose down
```

## Database Configuration

- The L4D2 server connects to the database using configuration in `databases.cfg`
- Database connection details are managed through environment variables in `.env`
- Default database name: `left4dead2`
- Required MariaDB version: 10.7+ (for UUID data type support)

## SourceMod Plugin Development

### Key Plugin Features
- **Stats Recording**: Player actions, weapon usage, map completion, points system
- **Skill Detection**: Advanced gameplay mechanics (skeets, crowns, levels, bunny hops, etc.)
- **Heatmap Generation**: Player position tracking with coordinate rounding
- **Real-time Database Updates**: Continuous statistics recording during gameplay

### Plugin Dependencies
- SourceMod framework
- Left4DHooks extension
- Various includes: `jutils.inc`, `l4d_info_editor.inc`, etc.

## Important Files

- `stats_database.sql`: Complete database schema
- `docker-compose.yaml`: Full development environment setup
- `databases.cfg.example`: Template for L4D2 server database configuration
- Various `.sql` files: Database maintenance and fix scripts

## Environment Setup

1. **Database**: Use Docker Compose for local development
2. **API Development**: Node.js with nodemon for auto-restart
3. **UI Development**: Vue CLI development server
4. **Plugin Development**: SourceMod compiler for .sp to .smx conversion

## Network Architecture

- **Database**: Port 3306 (MariaDB)
- **API**: Port 8081 (Express server)
- **UI**: Port 8080 (Vue development server)
- **phpMyAdmin**: Port 8082 (Database management)

## Key Technologies

- **Backend**: Node.js, Express, MySQL2, Canvas
- **Frontend**: Vue.js 2, Buefy, Chart.js, Vue Router
- **Database**: MariaDB 10.7+
- **Game Server**: SourceMod plugins (SourcePawn language)
- **Containerization**: Docker Compose

## Statistics Tracking

The system tracks comprehensive L4D2 gameplay statistics including:
- Player performance metrics
- Weapon usage statistics
- Map completion data
- Skill-based actions (skeets, crowns, etc.)
- Session-based gameplay tracking
- Geographic player data via GeoIP
- Campaign progress and scoring

## Development Notes

- There is no need to compile. I will do manually