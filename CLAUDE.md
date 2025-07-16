# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a comprehensive Left 4 Dead 2 statistics tracking system featuring a **sophisticated four-tier point calculation architecture** with dual penalty systems and comprehensive player performance analytics:

- **SourceMod Plugins**: Two .sp files that run on the L4D2 server to track gameplay statistics
- **Website API**: Node.js Express server that provides REST endpoints for statistics data
- **Website UI**: Vue.js frontend for displaying player statistics and game data
- **Database**: MariaDB/MySQL database with map-based statistics architecture
- **Point System**: Four-tier calculation system (overall, map, MVP all-time, MVP per map)
- **Configuration**: Fully configurable rules via point-system.json

## System Architecture Summary

### Four-Tier Point Calculation System
1. **Overall Points**: Lifetime cumulative statistics across all maps (harsh FF penalties)
2. **Map Points**: Map-specific statistics with same penalty system as overall
3. **MVP All Time**: Global champion recognition (lighter FF penalties)
4. **MVP per Map**: Map-specific champion recognition (lighter FF penalties)

### Dual Penalty Philosophy
- **Rankings System**: Harsh FF penalties (-40 per damage) for competitive integrity
- **MVP System**: Lighter FF penalties (-3 multiplier) for skill recognition
- **Configurable**: All penalty values adjustable in point-system.json

### Map-Based Database Architecture
- **stats_users**: Lifetime cumulative statistics
- **stats_map_users**: Map-specific performance tracking
- **stats_games**: Individual session records
- **Referential Integrity**: Foreign key relationships ensure data consistency

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
- Player performance metrics with enhanced activity detection
- Weapon usage statistics and skill-based actions (skeets, crowns, etc.)
- Map completion data with session-based tracking
- Geographic player data via GeoIP
- Campaign progress and scoring with dual penalty systems
- Real-time point calculation with configurable rules

### Enhanced Activity Detection
- **Comprehensive Tracking**: Multiple activity indicators prevent data loss
- **Multi-Factor Detection**: Time-based, action-based, and interaction-based criteria
- **Edge Case Handling**: Graceful accommodation of various play styles
- **Quality Assurance**: Regular validation ensures detection accuracy

## Four-Tier Point Calculation System

### Architecture Overview
The system implements four distinct point calculation tiers, each serving different purposes:

#### 1. Overall Points (Global Rankings)
- **Data Source**: `stats_users` table (lifetime cumulative stats)
- **Penalty System**: Harsh FF penalties (-40 per damage) for competitive integrity
- **Purpose**: Global leaderboards and long-term player rankings
- **Configuration**: `point-system.json` → `penalties.friendly_fire_damage`

#### 2. Map Points (Map-Specific Rankings)
- **Data Source**: `stats_map_users` table (map-specific stats)
- **Penalty System**: Same harsh FF penalties as overall (-40 per damage)
- **Purpose**: Map-specific leaderboards and comparative analysis
- **Configuration**: `point-system.json` → `penalties.friendly_fire_damage`

#### 3. MVP All Time (Global Champion)
- **Data Source**: `stats_users` table (lifetime stats)
- **Penalty System**: Lighter FF penalties (-3 multiplier) for skill recognition
- **Purpose**: Overall champion recognition focusing on positive contributions
- **Configuration**: `point-system.json` → `mvp_calculation.point_values.penalties`

#### 4. MVP per Map (Map Champion)
- **Data Source**: `stats_map_users` table (map-specific stats)
- **Penalty System**: Lighter FF penalties (-3 multiplier) for skill recognition
- **Purpose**: Map-specific champion recognition
- **Configuration**: `point-system.json` → `mvp_calculation.point_values.penalties`

### MVPCalculator Service
The `MVPCalculator.js` service provides centralized MVP calculation logic:

**Key Features:**
- Singleton pattern for consistent calculations across all endpoints
- Configurable point values loaded from `point-system.json`
- Comprehensive scoring algorithm with positive actions and penalties
- Damage taken bonus system (rewards taking less damage than average)
- Fallback ranking criteria for tie-breaking

**Point System (MVP Calculations):**
- **Positive Actions**: Common kills (+1), Special kills (+6), Tank kills (+100), Witch kills (+15), Healing (+40), Reviving (+25), Defibs (+30), Finale wins (+1000)
- **Penalties**: Teammate kills (-100), Friendly fire damage (-3 multiplier)
- **Bonuses**: Damage taken bonus (+(avg_damage - player_damage) × 0.5)

**Usage:**
```javascript
import MVPCalculator from './services/MVPCalculator.js'

// Calculate MVP points for a player
const mvpPoints = MVPCalculator.calculateMVPPoints(playerData, avgDamageTaken)

// Calculate and mark MVP for a group of players
const playersWithMVP = MVPCalculator.calculateAndMarkMVP(players)
```

### Configuration Management
- **File**: `/website-api/config/point-system.json`
- **Principle**: ALL calculations MUST strictly follow configuration (no hardcoded values)
- **Flexibility**: Complete rule customization without code changes
- **Reload**: Restart API and run `/api/recalculate` for configuration changes

### Dual Penalty System Rationale
**Rankings System (-40 FF penalty):**
- Long-term competitive integrity
- Rewards disciplined, team-first play
- Prevents careless friendly fire

**MVP System (-3 FF penalty):**
- Focuses on positive skill recognition
- Allows skilled players with minor FF to compete for MVP
- Encourages exceptional performance

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

## Recent Improvements & System Status

### Data Consistency Enhancements
- **Unified Point System**: All endpoints return identical point values from database
- **kills_all_specials Update**: Fixed aggregation in both `stats_users` and `stats_map_users`
- **Negative Points Support**: Updated database schema to allow negative point values
- **Point Recalculation**: Comprehensive `/api/recalculate` endpoint for rule changes

### Enhanced Activity Detection
- **Multi-Factor Detection**: Time-based, action-based, and interaction-based criteria
- **Data Loss Prevention**: Comprehensive checks prevent missing active player data
- **Edge Case Handling**: Graceful accommodation of various play styles
- **Quality Assurance**: Regular validation ensures detection accuracy

### System Monitoring & Health
- **Health Endpoint**: `/api/health` provides system status and metrics
- **Diagnostic Tools**: Comprehensive database maintenance and validation scripts
- **Performance Metrics**: User activity, session quality, and data integrity monitoring
- **Configuration Validation**: Runtime checks ensure point-system.json integrity

### Recent Fixes Applied
- **Tank Damage Double-Counting**: Fixed by disabling tank_damage rule in favor of tank_kill_max
- **Friendly Fire Penalties**: Verified dual penalty system implementation
- **Point Calculation Consistency**: Eliminated discrepancies between different views
- **MVP System Integration**: Both all-time and per-map MVP fully operational

## Development Notes

- SourceMod plugin compilation is done manually, no need to compile via Claude
- UI development uses Vue.js 2 with Buefy component library
- API uses ES6 modules (`"type": "module"` in package.json)
- All point calculations MUST follow point-system.json configuration
- Never hardcode point values or penalties in calculation logic

## SSH and Git Workflow

- When accessing ssh-homelab mcp for the left4dead2-stats project, always do a `git pull` first to get all updates

## Comprehensive Documentation Reference

For detailed technical information, refer to these documentation files:

### Feature Documentation
- **`docs/features/POINT_CALCULATION_SYSTEM.md`**: Complete four-tier point system documentation
- **`docs/features/MVP_CALCULATION_RULES.md`**: MVP system rules and configuration
- **`docs/features/PENALTY_SYSTEM_DESIGN.md`**: Dual penalty system design and rationale
- **`docs/features/MAP_BASED_STATISTICS_ARCHITECTURE.md`**: Map-based database architecture
- **`docs/features/ENHANCEMENT_IMPROVEMENTS.md`**: Recent improvements and system monitoring

### Setup Documentation
- **`docs/setup/DOCKER-SETUP.md`**: Docker environment setup guide
- **`README.md`**: Basic setup and Docker configuration

### Troubleshooting
- **`docs/troubleshooting/`**: Issues and fixes documentation
- **`docs/reports/`**: Testing and debugging reports

## System Status Summary

### ✅ Fully Operational
- Four-tier point calculation system
- Dual penalty system (rankings vs MVP)
- Map-based statistics architecture
- MVP calculations (all-time and per-map)
- Configuration-driven design
- Enhanced activity detection
- System health monitoring

### 🔧 Configuration-Driven
- All point values configurable in `point-system.json`
- No hardcoded values in calculation logic
- Runtime configuration changes supported
- Comprehensive validation rules

### 📊 Data Integrity
- Unified point system across all endpoints
- Referential integrity with foreign key constraints
- Regular consistency checks and validation
- Comprehensive diagnostic capabilities

---

**Last Updated**: 2025-01-16  
**System Version**: 4-Tier Point Calculation Architecture  
**Status**: Production-ready with comprehensive monitoring