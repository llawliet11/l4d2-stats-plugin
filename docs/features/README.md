# Features Documentation

This directory contains knowledge documentation for the L4D2 Stats Plugin's core features and systems.

## Available Documentation

### Core Systems
- **[POINT_CALCULATION_SYSTEM.md](POINT_CALCULATION_SYSTEM.md)** - Four-tier point calculation architecture
- **[MVP_CALCULATION_RULES.md](MVP_CALCULATION_RULES.md)** - MVP determination system and rules
- **[PENALTY_SYSTEM_DESIGN.md](PENALTY_SYSTEM_DESIGN.md)** - Dual penalty system design rationale

### Architecture
- **[MAP_BASED_STATISTICS_ARCHITECTURE.md](MAP_BASED_STATISTICS_ARCHITECTURE.md)** - Map-based statistics system
- **[ENHANCEMENT_IMPROVEMENTS.md](ENHANCEMENT_IMPROVEMENTS.md)** - System reliability and quality enhancements

## System Overview

### Point Calculation Architecture
- **Four-tier system**: Overall Points, Map Points, MVP All Time, MVP of Map
- **Configuration-driven**: All rules defined in `point-system.json`
- **Dual penalty system**: Different penalties for rankings vs MVP determination

### Statistics Architecture
- **Three-table system**: `stats_users`, `stats_map_users`, `stats_games`
- **Map-based tracking**: Granular statistics per map with session tracking
- **Data integrity**: Foreign key relationships and consistency validation

### Quality & Reliability
- **Data consistency**: Unified point system across all interfaces
- **Activity detection**: Comprehensive player activity tracking
- **System monitoring**: Health checks and diagnostic capabilities

## Key Principles

### Configuration-Driven Design
- **No hardcoded values**: All rules configurable in JSON files
- **Runtime flexibility**: Configuration changes supported
- **Future-proof**: Easy modification without code changes

### Data Integrity
- **Single source of truth**: Database points are authoritative
- **Consistency validation**: Regular checks ensure accuracy
- **Comprehensive tracking**: All meaningful activity captured

### Operational Excellence
- **Proactive monitoring**: Health checks and diagnostics
- **Quality assurance**: Comprehensive validation procedures
- **Documentation**: Clear guidance for system operation