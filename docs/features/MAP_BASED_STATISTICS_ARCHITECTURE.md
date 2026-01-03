# Map-Based Statistics System

## Overview
The L4D2 Stats Plugin implements a **map-based statistics architecture** that tracks player performance at both map-specific and lifetime levels. This system provides granular statistics while maintaining data integrity.

## Database Architecture

### Three-Table System
1. **`stats_users`** - Lifetime cumulative statistics across all maps
2. **`stats_map_users`** - Map-specific statistics per player per map
3. **`stats_games`** - Individual session records

### Data Relationship
- `stats_users` contains aggregated totals from all maps
- `stats_map_users` contains per-map performance data
- `stats_games` contains individual session details
- Map information linked via `map_info` table

## Key Concepts

### Map-Based Approach Benefits
- **mapid always available**: Unlike campaignID, mapid is available throughout gameplay
- **Natural granularity**: Maps are the actual gameplay units players experience
- **Session tracking**: Clear start/end points for individual map sessions
- **Data integrity**: Proper database relationships with foreign keys

## Table Structure

### stats_map_users Table
**Purpose**: Track player statistics per map with session information

**Key Fields**:
- All fields from `stats_users` (inherited structure)
- `mapid` - Map identifier (links to map_info)
- `session_start` - Session start timestamp
- `session_end` - Session end timestamp

**Primary Key**: `(steamid, mapid, session_start)`

**Relationships**:
- Foreign key to `map_info` table via `mapid`
- Links to `stats_users` via `steamid`

### Data Flow
1. **Session Start**: New record created in `stats_map_users`
2. **During Play**: Map-specific stats updated in real-time
3. **Session End**: `session_end` timestamp recorded
4. **Aggregation**: `stats_users` updated with cumulative totals

## Current Implementation Status

### Existing Data
- **stats_users**: Contains lifetime cumulative statistics
- **stats_map_users**: Contains map-specific statistics (currently `requiem_05`)
- **stats_games**: Contains individual session records

### Data Consistency
- `stats_users` totals should equal sum of `stats_map_users` for each player
- Map-specific data provides granular performance analysis
- Session tracking enables temporal analysis of player improvement

## Plugin Integration

### SourcePawn Plugin Role
The `l4d2_stats_recorder.sp` plugin handles:
- **Dual Recording**: Updates both `stats_map_users` and `stats_users` tables
- **Session Tracking**: Records session start/end timestamps
- **Map Awareness**: Uses `mapid` for map-specific statistics
- **Data Aggregation**: Maintains lifetime totals in `stats_users`

### Recording Strategy
1. **Map Session Start**: Create new `stats_map_users` record
2. **Real-time Updates**: Update map-specific stats during gameplay
3. **Session End**: Record end timestamp and finalize session
4. **Lifetime Aggregation**: Update cumulative totals in `stats_users`

## Use Cases

### Map-Specific Analysis
- **Map Leaderboards**: Compare player performance on specific maps
- **Progress Tracking**: See improvement over multiple plays of same map
- **Map Difficulty Analysis**: Understand which maps are more challenging
- **Session Comparison**: Compare different sessions on the same map

### Lifetime Analysis
- **Overall Rankings**: Global leaderboards across all maps
- **Career Progression**: Long-term player development
- **Total Achievements**: Cumulative accomplishments
- **Cross-Map Performance**: Performance consistency across different maps

### Combined Insights
- **Map Specialization**: Which maps players perform best on
- **Skill Development**: How performance improves over time
- **Comparative Analysis**: Map-specific vs overall performance
- **MVP Determination**: Both map-specific and global MVP calculations

## Data Integrity

### Consistency Requirements
- `stats_users` totals must equal sum of `stats_map_users` for each player
- All map sessions must have valid `mapid` references
- Session timestamps must be logical (start < end)
- Foreign key relationships must be maintained

### Validation Concepts
- **Aggregation Accuracy**: Lifetime totals match map-specific sums
- **Referential Integrity**: All map references are valid
- **Temporal Consistency**: Session times are logical
- **Data Completeness**: No missing required fields

## Performance Considerations

### Database Optimization
- **Indexing**: Proper indexes on `mapid`, `steamid`, and session timestamps
- **Query Efficiency**: Optimized queries for common access patterns
- **Storage**: Efficient storage of duplicate player information
- **Relationships**: Foreign key constraints for data integrity

### Access Patterns
- **Map Leaderboards**: Frequent queries by `mapid`
- **Player History**: Queries by `steamid` across maps
- **Session Analysis**: Time-based queries for progression
- **Aggregation**: Lifetime totals from map-specific data

## Advantages of Map-Based Architecture

### Technical Benefits
- **Consistent Availability**: `mapid` is available throughout all plugin operations
- **Natural Granularity**: Maps are the actual gameplay units players experience
- **Metadata Integration**: Links with `map_info` for chapter counts and map details
- **Session Boundaries**: Clear start/end points for individual map sessions
- **Data Integrity**: Foreign key relationships ensure referential integrity

### Functional Benefits
- **Granular Analysis**: Compare performance on specific maps
- **Progress Tracking**: Monitor improvement over multiple plays of same map
- **Difficulty Assessment**: Understand which maps are more challenging
- **Flexible Aggregation**: Can group maps into campaigns when needed
- **Temporal Analysis**: Track performance changes over time

## System Benefits

### Data Quality
- **Referential Integrity**: Foreign key constraints prevent orphaned data
- **Consistency Checks**: Aggregation validation ensures data accuracy
- **Audit Trail**: Session tracking provides complete gameplay history
- **Scalability**: Architecture supports unlimited maps and sessions

### Analytical Capabilities
- **Multi-Level Analysis**: Individual sessions, map totals, and lifetime statistics
- **Comparative Studies**: Performance across different maps and time periods
- **Trend Analysis**: Player improvement and skill development tracking
- **Competitive Insights**: Map-specific leaderboards and rankings

---

**Architecture Status**: Implemented and operational
**Current Maps**: `requiem_05` with full session tracking
**Data Integrity**: Maintained through foreign key relationships
**Performance**: Optimized with proper indexing strategy