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

### Local Development Setup
```bash
# Prerequisites: Node.js 18+, Yarn, Docker, Docker Compose

# Quick start for local development
docker compose up -d --build && bash ui-local.sh

# Access services:
# UI: http://l4d2stats-nginx.l4d2-stats-plugin.orb.local
# API: http://l4d2stats-api.l4d2-stats-plugin.orb.local  
# Database: mariadb.l4d2-stats-plugin.orb.local
# phpMyAdmin: http://localhost:8082
```

### Build Scripts
```bash
# For local development (builds UI and starts all services)
./ui-local.sh

# Quick rebuild (faster, doesn't remove containers)
./quick-rebuild.sh

# One-time production build
./build-once.sh

# Reset database to clean state
./reset_database.sh
```

### Manual Development Commands

#### Website API
```bash
cd website-api
yarn install
yarn dev        # Development with nodemon
yarn start      # Production
```

#### Website UI
```bash
cd website-ui
yarn install
yarn serve      # Development server with hot-reload
yarn build      # Production build
yarn lint       # ESLint with auto-fix
```

#### Docker Development
```bash
# Start all services (MariaDB, API, UI, phpMyAdmin)
docker compose up -d

# Check service status
docker compose ps

# View logs
docker compose logs [service-name]

# Stop services
docker compose down
```

## Configuration Management

### Environment Variables
Copy `.env.example` to `.env` and configure:
- Database credentials (MARIADB_ROOT_PASSWORD, MARIADB_USER, MARIADB_PASSWORD)
- Service ports (API_PORT, UI_PORT)
- Database connection settings (MYSQL_HOST, MYSQL_DB, MYSQL_USER, MYSQL_PASSWORD)

### Vue.js Configuration
- `vue.config.js`: Development proxy configuration
- Proxies `/api` requests to `l4d2stats-api.l4d2-stats-plugin.orb.local` for local development
- For production, API runs on port 8081

### Database Configuration
- The L4D2 server connects to the database using configuration in `databases.cfg`
- Database connection details are managed through environment variables in `.env`
- Default database name: `left4dead2`
- Required MariaDB version: 10.7+ (for UUID data type support)
- Database access: `docker exec -it [container_name] mariadb -u root -p`

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

## Key File Structure

### SourceMod Plugins
- `/scripting/l4d2_stats_recorder.sp`: Main statistics recorder plugin
- `/scripting/l4d2_skill_detect.sp`: Skill detection system
- `/scripting/include/`: Plugin dependencies and includes
- `/plugins/`: Compiled plugin files (`.smx`)

### API Components
- `/website-api/index.js`: Main API server entry point
- `/website-api/routes/`: API route handlers (campaigns, maps, sessions, users, misc)
- `/website-api/services/`: Business logic services
  - `MVPCalculator.js`: Centralized MVP calculation service (singleton)
- `/website-api/config/`: Configuration files and point system rules
  - `point-system.json`: Comprehensive point calculation and MVP system configuration

### UI Components
- `/website-ui/src/views/`: Main page components (Home, Stats, Leaderboard, etc.)
- `/website-ui/src/components/`: Reusable Vue components
- `/website-ui/src/router/`: Vue Router configuration
- `/website-ui/dist/`: Built production files (generated)

### Configuration and Setup
- `stats_database.sql`: Complete database schema
- `docker-compose.yaml`: Full development environment setup
- `databases.cfg.example`: Template for L4D2 server database configuration
- `.env.example`: Environment variable template
- Various `.sql` files: Database maintenance and fix scripts

### Build Scripts
- `ui-local.sh`: Local development build script
- `quick-rebuild.sh`: Fast rebuild for development
- `build-once.sh`: One-time production build
- `reset_database.sh`: Database reset utility

### Documentation
- `/docs/`: Comprehensive project documentation
  - `features/MVP_CALCULATION_RULES.md`: MVP system documentation
  - `features/ENHANCEMENT_IMPROVEMENTS.md`: Recent API and plugin improvements
  - `setup/DOCKER-SETUP.md`: Docker environment setup guide
  - `troubleshooting/`: Issues and fixes documentation
  - `reports/`: Testing and debugging reports

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

## MVP Calculation System

### MVPCalculator Service
The `MVPCalculator.js` service provides centralized MVP calculation logic:

**Key Features:**
- Singleton pattern for consistent calculations across all endpoints
- Configurable point values loaded from `point-system.json`
- Comprehensive scoring algorithm with positive actions and penalties
- Damage taken bonus system (rewards taking less damage than average)
- Fallback ranking criteria for tie-breaking

**Point System:**
- **Positive Actions**: Common kills (+1), Special kills (+6), Tank kills (+100), Witch kills (+15), Healing (+40), Reviving (+25), Defibs (+30), Finale wins (+1000)
- **Penalties**: Teammate kills (-100), Friendly fire damage (-2 per HP)
- **Bonuses**: Damage taken bonus (+(avg_damage - player_damage) × 0.5)

**Usage:**
```javascript
import MVPCalculator from './services/MVPCalculator.js'

// Calculate MVP points for a player
const mvpPoints = MVPCalculator.calculateMVPPoints(playerData, avgDamageTaken)

// Calculate and mark MVP for a group of players
const playersWithMVP = MVPCalculator.calculateAndMarkMVP(players)
```

### Configuration
- Point values and rules are stored in `/website-api/config/point-system.json`
- System supports comprehensive configuration with enabled/disabled features
- Fallback defaults are provided if configuration file is missing
- Configuration includes validation rules and reasonable value limits

## Testing and Code Quality

### ESLint Configuration
- UI uses ESLint with Vue.js rules and Standard configuration
- Pre-commit hooks configured via lint-staged
- Run linting: `cd website-ui && yarn lint`
- Auto-fix on commit via git hooks

### No Unit Tests
- Currently no Jest/Vitest test suites configured
- Testing is primarily manual through the UI
- Database testing via phpMyAdmin interface

## Docker Service Architecture

### Service Components
- **mariadb**: Database server (MariaDB 11+)
- **l4d2stats-api**: Node.js API server (Express with MySQL2)
- **l4d2stats-ui**: Vue.js build container (one-time build)
- **l4d2stats-nginx**: Nginx reverse proxy and static file server
- **l4d2stats-phpmyadmin**: Database management interface

### Service Dependencies
- API depends on MariaDB being ready
- UI build depends on API being available (for proxy configuration)
- Nginx serves built UI files and proxies API requests

## Troubleshooting

### Common Issues
- **Port conflicts**: Ensure ports 3306, 8080, 8081, 8082 are available
- **Database connection**: Verify MariaDB container is running with `docker compose ps`
- **API errors**: Check API logs with `docker compose logs l4d2stats-api`
- **UI build failures**: Ensure Node.js 18+ and yarn are installed

### Logs and Debugging
- View all logs: `docker compose logs -f`
- Specific service: `docker compose logs -f [service-name]`
- Database logs: `docker compose logs -f mariadb`
- Follow build progress: `docker compose logs -f l4d2stats-ui`

### Database Backup and Restore
```bash
# Backup database
docker compose exec mariadb mysqldump -u root -p left4dead2 > backup.sql

# Restore database
cat backup.sql | docker compose exec -T mariadb mysql -u root -p left4dead2
```

### API Health Monitoring
```bash
# Check API health and database statistics
curl http://localhost:8081/api/health

# Returns user counts, playtime stats, session metrics, and system health
```

## Recent Improvements

### API Consistency Fixes
- **Search Endpoint**: Fixed to use database points instead of calculated values
- **User Endpoints**: Updated `/random` and `/:user` to use consistent database points
- **Point System**: All endpoints now return identical point values across the application

### Enhanced Plugin Logic
- **Activity Detection**: Improved detection to prevent data loss
- **Additional Checks**: Added door opens and damage dealt as activity indicators
- **Comprehensive Logging**: Better activity tracking for edge cases

### Database Health Monitoring
- **Health Endpoint**: New `/api/health` endpoint for monitoring system status
- **Diagnostic Tools**: `database_maintenance.sql` with comprehensive diagnostic queries
- **Performance Metrics**: User activity, session quality, and data integrity checks

## Development Notes

- SourceMod plugin compilation is done manually, no need to compile via Claude
- UI development uses Vue.js 2 with Buefy component library
- API uses ES6 modules (`"type": "module"` in package.json)

## SSH and Git Workflow

- When accessing ssh-homelab mcp for the left4dead2-stats project, always do a `git pull` first to get all updates