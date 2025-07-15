# Stats Map Users Implementation Plan

## Overview
This document outlines the implementation plan for creating a new `stats_map_users` table to track per-map user statistics while maintaining accurate lifetime totals in the existing `stats_users` table.

## Current Problem
- `stats_users` contains accurate lifetime totals (e.g., GOD: 3,749 common kills)
- `stats_games` contains per-game records but with potentially inconsistent data (e.g., GOD: 320 kills in single campaign)
- No way to track user performance per map while maintaining data integrity
- Need granular map-level statistics with chapter information

## Proposed Solution
Create `stats_map_users` table that combines the accuracy of `stats_users` with map-level granularity, making `stats_users` an aggregated view of map data. This approach uses `mapid` (always available) instead of `campaignID` (only available at finale).

## Implementation Phases

### Phase 1: Database Schema Changes

#### 1.1 Create stats_map_users Table
```sql
-- Create table with ALL columns from stats_users structure
CREATE TABLE stats_map_users LIKE stats_users;

-- IMPORTANT: stats_map_users inherits ALL columns from stats_users:
-- steamid, last_alias, last_join_date, created_date, connections, country, points,
-- survivor_deaths, infected_deaths, survivor_damage_rec, survivor_damage_give,
-- infected_damage_rec, infected_damage_give, pickups_molotov, pickups_pipe_bomb,
-- survivor_incaps, pills_used, defibs_used, adrenaline_used, heal_self, heal_others,
-- revived, revived_others, pickups_pain_pills, melee_kills, tanks_killed,
-- tanks_killed_solo, tanks_killed_melee, survivor_ff, survivor_ff_rec, common_kills,
-- common_headshots, door_opens, damage_to_tank, damage_as_tank, damage_witch,
-- minutes_played, finales_won, kills_smoker, kills_boomer, kills_hunter,
-- kills_spitter, kills_jockey, kills_charger, kills_witch, packs_used, ff_kills,
-- throws_puke, throws_molotov, throws_pipe, damage_molotov, kills_molotov,
-- kills_pipe, kills_minigun, kills_all_specials, caralarms_activated,
-- witches_crowned, witches_crowned_angry, smokers_selfcleared, rocks_hitby,
-- hunters_deadstopped, cleared_pinned, times_pinned, clowns_honked, minutes_idle,
-- boomer_mellos, boomer_mellos_self, forgot_kit_count, total_distance_travelled,
-- mvp_wins, ff_damage_received

-- Add map-specific additional columns
ALTER TABLE stats_map_users ADD COLUMN mapid varchar(32) NOT NULL;
ALTER TABLE stats_map_users ADD COLUMN session_start bigint(20) unsigned NOT NULL;
ALTER TABLE stats_map_users ADD COLUMN session_end bigint(20) unsigned DEFAULT NULL;

-- Update primary key to include map and session
ALTER TABLE stats_map_users DROP PRIMARY KEY;
ALTER TABLE stats_map_users ADD PRIMARY KEY (steamid, mapid, session_start);

-- Add indexes for performance
CREATE INDEX idx_map_users_mapid ON stats_map_users(mapid);
CREATE INDEX idx_map_users_steamid ON stats_map_users(steamid);
CREATE INDEX idx_map_users_session ON stats_map_users(session_start, session_end);

-- Add foreign key relationships
ALTER TABLE stats_map_users ADD CONSTRAINT fk_map_users_mapid 
    FOREIGN KEY (mapid) REFERENCES map_info(mapid) ON UPDATE CASCADE;
```

#### 1.2 Data Migration for Current Map
```sql
-- Migrate existing data from stats_users to stats_map_users
-- This preserves ALL existing stats_users data and adds map-specific columns
-- For the single current map (requiem_05)
INSERT INTO stats_map_users (
    -- ALL stats_users columns (inherited via CREATE TABLE LIKE)
    steamid, last_alias, last_join_date, created_date, connections, country, points,
    survivor_deaths, infected_deaths, survivor_damage_rec, survivor_damage_give,
    infected_damage_rec, infected_damage_give, pickups_molotov, pickups_pipe_bomb,
    survivor_incaps, pills_used, defibs_used, adrenaline_used, heal_self, heal_others,
    revived, revived_others, pickups_pain_pills, melee_kills, tanks_killed,
    tanks_killed_solo, tanks_killed_melee, survivor_ff, survivor_ff_rec, common_kills,
    common_headshots, door_opens, damage_to_tank, damage_as_tank, damage_witch,
    minutes_played, finales_won, kills_smoker, kills_boomer, kills_hunter,
    kills_spitter, kills_jockey, kills_charger, kills_witch, packs_used, ff_kills,
    throws_puke, throws_molotov, throws_pipe, damage_molotov, kills_molotov,
    kills_pipe, kills_minigun, kills_all_specials, caralarms_activated,
    witches_crowned, witches_crowned_angry, smokers_selfcleared, rocks_hitby,
    hunters_deadstopped, cleared_pinned, times_pinned, clowns_honked, minutes_idle,
    boomer_mellos, boomer_mellos_self, forgot_kit_count, total_distance_travelled,
    mvp_wins, ff_damage_received,
    -- Additional map-specific columns
    mapid, session_start, session_end
)
SELECT 
    -- ALL stats_users data
    u.*,
    -- Additional map-specific data
    'requiem_05' as mapid,
    (SELECT MIN(date_start) FROM stats_games WHERE steamid = u.steamid) as session_start,
    (SELECT MAX(date_end) FROM stats_games WHERE steamid = u.steamid) as session_end
FROM stats_users u
WHERE u.steamid IN (
    SELECT DISTINCT steamid FROM stats_games 
    WHERE map = 'requiem_05'
);
```

### Phase 2: Plugin Modifications

#### 2.1 Modify l4d2_stats_recorder.sp
- Update database schema awareness
- Add functions to insert/update stats_map_users
- Maintain backward compatibility with stats_users
- Add map-level statistics tracking using available mapid

#### 2.2 Data Recording Strategy
```cpp
// Pseudo-code for plugin modifications
void UpdatePlayerStats(steamid, mapid, stats) {
    // Update per-map stats (mapid is always available via game.mapId)
    UpdateMapUserStats(steamid, mapid, stats);
    
    // Update lifetime totals (aggregate from all maps)
    UpdateLifetimeStats(steamid);
}

void UpdateMapUserStats(steamid, mapid, stats) {
    // Insert or update current map session stats
    ExecuteQuery("
        INSERT INTO stats_map_users (steamid, mapid, session_start, common_kills, ...) 
        VALUES ('%s', '%s', %d, %d, ...) 
        ON DUPLICATE KEY UPDATE 
            common_kills = common_kills + %d,
            survivor_deaths = survivor_deaths + %d,
            session_end = UNIX_TIMESTAMP()
    ", steamid, mapid, session_start, stats...);
}

void UpdateLifetimeStats(steamid) {
    // Aggregate all map stats for this user
    ExecuteQuery("
        UPDATE stats_users u SET 
            common_kills = (SELECT SUM(common_kills) FROM stats_map_users smu WHERE smu.steamid = u.steamid),
            survivor_deaths = (SELECT SUM(survivor_deaths) FROM stats_map_users smu WHERE smu.steamid = u.steamid),
            -- ... other fields
        WHERE u.steamid = '%s'
    ", steamid);
}

// Track session start on map load or player connect
void OnPlayerMapConnect(client) {
    players[client].mapSessionStart = GetTime();
}
```

### Phase 3: API Endpoint Modifications

#### 3.1 Sessions Endpoint (routes/sessions.js)
- **Option A**: Keep current behavior (use stats_users for lifetime totals)
- **Option B**: Add map filter parameter to show map-specific stats
- **Option C**: Add aggregation level parameter (lifetime/map/session)

#### 3.2 Maps Endpoint Enhancement
- Add user performance data per map
- Show map-specific leaderboards
- Include chapter information from map_info

#### 3.3 New Endpoint: Map User Stats
```javascript
// GET /api/maps/:mapid/users
router.get('/:mapid/users', async (req, res) => {
    const [users] = await pool.query(`
        SELECT 
            smu.*,
            u.last_alias,
            i.name as map_name,
            i.chapter_count
        FROM stats_map_users smu
        JOIN stats_users u ON smu.steamid = u.steamid
        LEFT JOIN map_info i ON i.mapid = smu.mapid
        WHERE smu.mapid = ?
        ORDER BY smu.points DESC
    `, [req.params.mapid]);
    
    res.json({ users });
});

// GET /api/users/:steamid/maps
router.get('/users/:steamid/maps', async (req, res) => {
    const [mapStats] = await pool.query(`
        SELECT 
            smu.*,
            i.name as map_name,
            i.chapter_count,
            FROM_UNIXTIME(smu.session_start) as session_start_time,
            FROM_UNIXTIME(smu.session_end) as session_end_time
        FROM stats_map_users smu
        LEFT JOIN map_info i ON i.mapid = smu.mapid
        WHERE smu.steamid = ?
        ORDER BY smu.session_start DESC
    `, [req.params.steamid]);
    
    res.json({ mapStats });
});
```

### Phase 4: Database Maintenance

#### 4.1 Data Consistency Checks
```sql
-- Verify stats_users equals sum of stats_map_users
SELECT 
    u.steamid,
    u.common_kills as lifetime_total,
    SUM(smu.common_kills) as map_sum,
    (u.common_kills - SUM(smu.common_kills)) as difference
FROM stats_users u
LEFT JOIN stats_map_users smu ON u.steamid = smu.steamid
GROUP BY u.steamid
HAVING difference != 0;

-- Verify map_info relationships
SELECT 
    smu.mapid,
    COUNT(*) as user_sessions,
    i.name as map_name,
    i.chapter_count
FROM stats_map_users smu
LEFT JOIN map_info i ON smu.mapid = i.mapid
WHERE i.mapid IS NULL
GROUP BY smu.mapid;
```

#### 4.2 Maintenance Procedures
- Regular data validation scripts
- Backup procedures for both tables
- Migration scripts for future schema changes

### Phase 5: Testing & Validation

#### 5.1 Data Integrity Tests
- Verify current data migration is accurate
- Test new campaign data recording
- Validate API endpoint responses

#### 5.2 Performance Testing
- Query performance with new table structure
- Index optimization if needed
- API response time validation

## Implementation Timeline

### Week 1: Database Implementation
- [ ] Create stats_map_users table
- [ ] Migrate current map data
- [ ] Validate data integrity
- [ ] Test foreign key relationships

### Week 2: Plugin Modifications
- [ ] Modify SourceMod plugin for map-based tracking
- [ ] Add session start/end tracking
- [ ] Test data recording functionality
- [ ] Deploy plugin updates

### Week 3: API & Frontend
- [ ] Update API endpoints for map statistics
- [ ] Add new map user endpoints
- [ ] Test map-specific queries
- [ ] Frontend integration if needed

### Week 4: Testing & Deployment
- [ ] End-to-end testing
- [ ] Performance validation with map indexing
- [ ] Production deployment

## Rollback Plan

### If Issues Arise
1. **Database**: Keep original stats_users table unchanged during migration
2. **Plugin**: Feature flag to disable new table writes
3. **API**: Fallback to original stats_users queries

### Emergency Procedures
- Restore from backup if data corruption occurs
- Disable plugin temporarily if recording issues
- Revert API changes if performance problems

## Success Metrics

### Data Quality
- stats_users totals match sum of stats_map_users
- No data loss during migration
- Consistent recording for new maps
- Proper foreign key relationships maintained

### Performance
- API response times remain under 200ms
- Database queries perform efficiently with map indexing
- Plugin overhead minimal for map session tracking

### Functionality
- Map-level user comparisons work correctly
- Lifetime totals still accurate
- New maps record properly with chapter information
- Session tracking works correctly

## Dependencies

### Database
- MariaDB 10.7+ (UUID support)
- Sufficient storage for new table
- Backup system in place

### SourceMod Plugin
- l4d2_stats_recorder.sp modifications for map tracking
- Session start/end tracking implementation
- Database connection pooling
- Error handling for dual writes
- Map ID availability verification

### API Layer
- Node.js MySQL2 compatibility
- Route caching updates for map endpoints
- Foreign key constraint handling
- Error handling improvements

## Risk Assessment

### High Risk
- Data migration accuracy for map sessions
- Plugin stability during dual writes
- Database performance impact with foreign keys
- Session tracking accuracy

### Medium Risk
- API endpoint compatibility
- Frontend integration changes
- Backup/restore procedures

### Low Risk
- Query performance optimization
- Documentation updates
- Testing coverage

## Key Advantages of Map-Based Approach

### Technical Benefits
- **mapid always available**: Unlike campaignID, mapid is available from OnMapStart() through all plugin operations
- **Natural granularity**: Maps are the actual gameplay units players experience
- **Chapter information**: Integration with map_info provides chapter counts and metadata
- **Session tracking**: Clear start/end points for individual map sessions
- **Foreign key integrity**: Proper database relationships with map_info table

### Functional Benefits
- **Map leaderboards**: Compare user performance on specific maps
- **Progress tracking**: See improvement over multiple plays of same map
- **Map difficulty analysis**: Understand which maps are more challenging
- **Campaign aggregation**: Can still group maps into campaigns when needed
- **Chapter statistics**: Track performance by campaign chapter count

## Notes

- This implementation preserves existing functionality while adding new capabilities
- Data migration is one-time for current map, future maps will record directly
- Plugin changes are backward compatible with added session tracking
- API changes are additive, not breaking
- Performance impact should be minimal with proper indexing
- Foreign key relationships ensure data integrity
- Map-based approach is more granular and technically sound than campaign-based

## Next Steps

1. Review this updated plan with development team
2. Set up development environment for testing
3. Begin Phase 1 implementation (database schema)
4. Establish testing procedures for map session tracking
5. Plan deployment timeline with session migration strategy