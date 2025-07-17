# L4D2 Stats Plugin Documentation

This directory contains comprehensive documentation for the Left 4 Dead 2 Statistics Plugin project.

## Documentation Structure

### 📋 Quick Start
- [Project Overview](../README.md) - Main project documentation
- [Setup Guide](setup/DOCKER-SETUP.md) - Docker development environment setup

### 🛠️ Development
- [Compilation Instructions](development/COMPILE_INSTRUCTIONS.md) - How to compile SourceMod plugins
- [AI Development Guide](../CLAUDE.md) - Instructions for AI-assisted development

### ✨ Core Systems & Features
- [Point Calculation System](features/POINT_CALCULATION_SYSTEM.md) - Four-tier point calculation architecture
- [MVP Calculation Rules](features/MVP_CALCULATION_RULES.md) - MVP determination system and rules
- [Penalty System Design](features/PENALTY_SYSTEM_DESIGN.md) - Dual penalty system rationale
- [Map-Based Statistics](features/MAP_BASED_STATISTICS_ARCHITECTURE.md) - Map-based statistics architecture
- [API Points Calculation Endpoints](features/API_POINTS_CALCULATION_ENDPOINTS.md) - API endpoints for point calculations
- [System Enhancements](features/ENHANCEMENT_IMPROVEMENTS.md) - Reliability and quality improvements

### 🔧 Troubleshooting
- [Point Calculation Issues](troubleshooting/POINT_CALCULATION_ISSUES.md) - Technical analysis of point calculation problems
- [Homepage Points Fix](troubleshooting/HOMEPAGE_POINTS_FIX.md) - Points display issues
- [Playtime & Points Fix Report](troubleshooting/PLAYTIME_AND_POINTS_FIX_REPORT.md) - Playtime calculation fixes

### 📊 Reports & Analysis
- [Debug Reports](reports/) - System debug and analysis reports

### 🏗️ Architecture & Design
- **Point Calculation**: Four-tier system with configurable rules
- **Statistics Architecture**: Map-based tracking with three-table design
- **Data Integrity**: Foreign key relationships and consistency validation
- **System Monitoring**: Health checks and diagnostic capabilities

## Quick Navigation

| Category | Purpose | Key Files |
|----------|---------|-----------|
| **Setup** | Getting started | `setup/DOCKER-SETUP.md` |
| **Development** | Building & coding | `development/COMPILE_INSTRUCTIONS.md`, `plan/DEVELOPMENT_ROADMAP_2025.md` |
| **Core Systems** | System architecture | `features/POINT_CALCULATION_SYSTEM.md`, `features/API_POINTS_CALCULATION_ENDPOINTS.md` |
| **Troubleshooting** | Problem solving | `troubleshooting/POINT_CALCULATION_ISSUES.md` |
| **Reports** | Analysis & debugging | `reports/testing_points_debug_20250715.md` |

## Key System Concepts

### Configuration-Driven Design
- **All rules configurable**: Point values, penalties, and calculations defined in JSON
- **No hardcoded values**: Complete flexibility without code changes
- **Runtime updates**: Configuration changes supported with API restart

### Four-Tier Point System
- **Overall Points**: Global rankings across all maps
- **Map Points**: Map-specific rankings and performance
- **MVP All Time**: Global champion determination
- **MVP of Map**: Map-specific champion recognition

### Data Architecture
- **Three-table system**: `stats_users`, `stats_map_users`, `stats_games`
- **Map-based tracking**: Granular statistics with session information
- **Data integrity**: Foreign key relationships and validation

## Documentation Philosophy

### Knowledge-Focused Approach
- **Concepts over implementation**: Focus on understanding systems rather than specific code
- **Configuration emphasis**: Highlight configurable aspects and flexibility
- **Architectural understanding**: Explain how systems work together
- **Troubleshooting guidance**: Provide diagnostic and problem-solving information

### Documentation Standards
- **Markdown format**: Use `.md` files with clear structure
- **Clear headings**: Organize content with logical hierarchy
- **Cross-references**: Link related concepts and documents
- **Current information**: Keep content accurate and up-to-date
- **Practical examples**: Include relevant examples and scenarios

### Contributing Guidelines
1. **Focus on knowledge**: Document concepts, not implementation details
2. **Emphasize configuration**: Highlight configurable aspects
3. **Update cross-references**: Maintain links between related documents
4. **Keep current**: Update information when systems change

---

**Documentation Status**: Knowledge-focused, configuration-driven
**Last Updated**: January 16, 2025
**Architecture**: Four-tier point system with map-based statistics