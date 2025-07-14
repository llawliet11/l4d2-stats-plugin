# Stats Campaigns Users Implementation Plan

## Overview
This document outlines the implementation plan for creating a new `stats_campaigns_users` table to track per-campaign user statistics while maintaining accurate lifetime totals in the existing `stats_users` table.

## Current Problem
- `stats_users` contains accurate lifetime totals (e.g., GOD: 3,749 common kills)
- `stats_games` contains per-game records but with potentially inconsistent data (e.g., GOD: 320 kills in single campaign)
- No way to track user performance per campaign while maintaining data integrity

## Proposed Solution
Create `stats_campaigns_users` table that combines the accuracy of `stats_users` with campaign-level granularity, making `stats_users` an aggregated view of campaign data.

## Implementation Phases

### Phase 1: Database Schema Changes

#### 1.1 Create stats_campaigns_users Table
```sql
-- Create table based on stats_users structure
CREATE TABLE stats_campaigns_users LIKE stats_users;

-- Add campaign-specific columns
ALTER TABLE stats_campaigns_users ADD COLUMN campaignID varchar(36) NOT NULL;
ALTER TABLE stats_campaigns_users ADD COLUMN map varchar(128) NOT NULL;

-- Update primary key to include campaign
ALTER TABLE stats_campaigns_users DROP PRIMARY KEY;
ALTER TABLE stats_campaigns_users ADD PRIMARY KEY (steamid, campaignID);

-- Add indexes for performance
CREATE INDEX idx_campaigns_users_campaign ON stats_campaigns_users(campaignID);
CREATE INDEX idx_campaigns_users_map ON stats_campaigns_users(map);
CREATE INDEX idx_campaigns_users_steamid ON stats_campaigns_users(steamid);
```

#### 1.2 Data Migration for Current Campaign
```sql
-- Migrate existing data from stats_users to stats_campaigns_users
-- For the single current campaign (requiem_05)
INSERT INTO stats_campaigns_users 
SELECT 
    u.*,
    '509bd8e6-5f15-11f0-976f-02420a0b0013' as campaignID,
    'requiem_05' as map
FROM stats_users u
WHERE u.steamid IN (
    SELECT DISTINCT steamid FROM stats_games 
    WHERE campaignID = '509bd8e6-5f15-11f0-976f-02420a0b0013'
);
```

### Phase 2: Plugin Modifications

#### 2.1 Modify l4d2_stats_recorder.sp
- Update database schema awareness
- Add functions to insert/update stats_campaigns_users
- Maintain backward compatibility with stats_users
- Add campaign-level statistics tracking

#### 2.2 Data Recording Strategy
```cpp
// Pseudo-code for plugin modifications
void UpdatePlayerStats(steamid, campaignID, map, stats) {
    // Update per-campaign stats
    UpdateCampaignUserStats(steamid, campaignID, map, stats);
    
    // Update lifetime totals (aggregate from all campaigns)
    UpdateLifetimeStats(steamid);
}

void UpdateLifetimeStats(steamid) {
    // Aggregate all campaign stats for this user
    ExecuteQuery("
        UPDATE stats_users u SET 
            common_kills = (SELECT SUM(common_kills) FROM stats_campaigns_users scu WHERE scu.steamid = u.steamid),
            survivor_deaths = (SELECT SUM(survivor_deaths) FROM stats_campaigns_users scu WHERE scu.steamid = u.steamid),
            -- ... other fields
        WHERE u.steamid = '%s'
    ", steamid);
}
```

### Phase 3: API Endpoint Modifications

#### 3.1 Sessions Endpoint (routes/sessions.js)
- **Option A**: Keep current behavior (use stats_users for lifetime totals)
- **Option B**: Add campaign filter parameter to show campaign-specific stats

#### 3.2 Campaigns Endpoint (routes/campaigns.js)
- Modify to use stats_campaigns_users for more accurate per-campaign user data
- Add user performance comparison within campaigns

#### 3.3 New Endpoint: Campaign User Stats
```javascript
// GET /api/campaigns/:campaignId/users
router.get('/:campaignId/users', async (req, res) => {
    const [users] = await pool.query(`
        SELECT 
            scu.*,
            u.last_alias,
            i.name as map_name
        FROM stats_campaigns_users scu
        JOIN stats_users u ON scu.steamid = u.steamid
        LEFT JOIN map_info i ON i.mapid = scu.map
        WHERE scu.campaignID = ?
        ORDER BY scu.points DESC
    `, [req.params.campaignId]);
    
    res.json({ users });
});
```

### Phase 4: Database Maintenance

#### 4.1 Data Consistency Checks
```sql
-- Verify stats_users equals sum of stats_campaigns_users
SELECT 
    u.steamid,
    u.common_kills as lifetime_total,
    SUM(scu.common_kills) as campaign_sum,
    (u.common_kills - SUM(scu.common_kills)) as difference
FROM stats_users u
LEFT JOIN stats_campaigns_users scu ON u.steamid = scu.steamid
GROUP BY u.steamid
HAVING difference != 0;
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
- [ ] Create stats_campaigns_users table
- [ ] Migrate current campaign data
- [ ] Validate data integrity

### Week 2: Plugin Modifications
- [ ] Modify SourceMod plugin
- [ ] Test data recording functionality
- [ ] Deploy plugin updates

### Week 3: API & Frontend
- [ ] Update API endpoints
- [ ] Test campaign-specific queries
- [ ] Frontend integration if needed

### Week 4: Testing & Deployment
- [ ] End-to-end testing
- [ ] Performance validation
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
- stats_users totals match sum of stats_campaigns_users
- No data loss during migration
- Consistent recording for new campaigns

### Performance
- API response times remain under 200ms
- Database queries perform efficiently
- Plugin overhead minimal

### Functionality
- Campaign-level user comparisons work correctly
- Lifetime totals still accurate
- New campaigns record properly

## Dependencies

### Database
- MariaDB 10.7+ (UUID support)
- Sufficient storage for new table
- Backup system in place

### SourceMod Plugin
- l4d2_stats_recorder.sp modifications
- Database connection pooling
- Error handling for dual writes

### API Layer
- Node.js MySQL2 compatibility
- Route caching updates
- Error handling improvements

## Risk Assessment

### High Risk
- Data migration accuracy
- Plugin stability during dual writes
- Database performance impact

### Medium Risk
- API endpoint compatibility
- Frontend integration changes
- Backup/restore procedures

### Low Risk
- Query performance optimization
- Documentation updates
- Testing coverage

## Notes

- This implementation preserves existing functionality while adding new capabilities
- Data migration is one-time for current campaign, future campaigns will record directly
- Plugin changes are backward compatible
- API changes are additive, not breaking
- Performance impact should be minimal with proper indexing

## Next Steps

1. Review this plan with development team
2. Set up development environment for testing
3. Begin Phase 1 implementation
4. Establish testing procedures
5. Plan deployment timeline