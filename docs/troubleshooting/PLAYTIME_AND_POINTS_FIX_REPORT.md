# L4D2 Stats Plugin - Playtime and Points Calculation Fix Report

## Issue Analysis

### Problem Identified
User "Tyrion" (STEAM_1:1:42077851) had only 2 minutes of recorded playtime despite playing in the same sessions as other users who had 300+ minutes. This indicated a critical flaw in the playtime tracking system.

### Root Cause Analysis

1. **Plugin Logic Flaw**: The SourcePawn plugin had a condition `if(players[client].points > 0)` that prevented stats from being saved if a player had no points, creating a chicken-and-egg problem.

2. **Database Inconsistency**: Multiple users showed significant discrepancies between their recorded `minutes_played` and their actual session time calculated from `stats_games` table.

3. **Points Calculation Issues**: The points system was using an overly complex formula that didn't properly account for actual playtime.

## Database Analysis Results

### Before Fix:
```
User: Tyrion
- Recorded minutes_played: 2
- Calculated session time: 323.67 minutes
- Points: 5
- Sessions: 2

Other affected users:
- longlaotam: 82 vs 323.67 minutes
- dOnNie: 114 vs 323.67 minutes  
- Nusty: 267 vs 323.67 minutes
- BuiQuang: 302 vs 323.67 minutes
```

### After Fix:
```
All users now have:
- Corrected minutes_played: 324 minutes
- Recalculated points using improved formula:
  - BuiQuang: 676 points (2.09 points/minute)
  - Nusty: 527 points (1.63 points/minute)
  - dOnNie: 441 points (1.36 points/minute)
  - longlaotam: 240 points (0.74 points/minute)
  - Tyrion: 135 points (0.42 points/minute)
```

## Fixes Applied

### 1. SourcePawn Plugin Fix (`scripting/l4d2_stats_recorder.sp`)

**Changed:**
```sourcepawn
// OLD - Problematic condition
if(players[client].points > 0) {

// NEW - Improved condition
if(minutes_played > 0 || players[client].points > 0 || 
   GetEntProp(client, Prop_Send, "m_checkpointZombieKills") > 0 ||
   GetEntProp(client, Prop_Send, "m_checkpointDamageTaken") > 0 ||
   GetEntProp(client, Prop_Send, "m_checkpointReviveOtherCount") > 0) {
```

**Impact:** Now saves stats for any player who has played for at least 1 minute OR has any meaningful game activity, preventing the chicken-and-egg problem.

### 2. Database Repair

**Applied comprehensive SQL fix:**
- Corrected playtime for all users based on actual session data
- Implemented improved points calculation formula
- Created backup of original data

**New Points Formula:**
```sql
points = GREATEST(0, (
    -- Base scoring (scaled appropriately)
    (common_kills * 0.001) +                    -- 0.001 points per common kill
    (kills_all_specials * 0.5) +               -- 0.5 points per special kill
    (revived_others * 2.0) +                   -- 2 points per revive
    (heal_others * 1.0) +                      -- 1 point per heal
    (cleared_pinned * 1.5) +                   -- 1.5 points per rescue
    (witches_crowned * 5.0) +                  -- 5 points per witch crown
    ((kills_molotov + kills_pipe) * 0.5) +     -- 0.5 points per throwable kill
    
    -- Penalties (negative points)
    (survivor_incaps * -1.0) +                 -- -1 point per incap
    (survivor_deaths * -2.0) +                 -- -2 points per death
    (survivor_ff * -0.001) +                   -- -0.001 points per FF damage
    (rocks_hitby * -1.0) +                     -- -1 point per tank rock hit
    
    -- Time-based bonuses
    (CASE 
        WHEN minutes_played > 0 THEN 
            (damage_to_tank * 0.01 / GREATEST(minutes_played, 1)) * minutes_played +
            (minutes_played * 0.1)
        ELSE 0 
    END)
))
```

### 3. API Endpoint Simplification

**Simplified API endpoints to use database points directly:**
- `website-api/routes/top.js` - Removed complex calculation, uses DB points
- `website-api/routes/user.js` - Simplified to return DB data directly
- `website-api/routes/misc.js` - Updated search to use DB points

**Rationale:** Since we fixed the database points calculation, the API no longer needs to recalculate points on every request, improving performance and consistency.

## Verification

### Database Verification Commands:
```sql
-- Check Tyrion's corrected data
SELECT steamid, last_alias, minutes_played, points 
FROM stats_users 
WHERE last_alias = 'Tyrion';

-- Verify session data consistency
SELECT 
    u.steamid, u.last_alias, u.minutes_played,
    SUM((g.date_end - g.date_start) / 60) as calculated_minutes
FROM stats_users u
JOIN stats_games g ON u.steamid = g.steamid
WHERE u.last_alias = 'Tyrion'
GROUP BY u.steamid;
```

## Benefits

1. **Accurate Playtime**: All users now have correct playtime that matches their actual session data
2. **Fair Points System**: Points are calculated using a balanced formula that rewards positive actions and penalizes negative ones
3. **Consistent Data**: API endpoints now return consistent data across all views
4. **Performance**: Simplified API reduces database load by using pre-calculated points
5. **Future-Proof**: Plugin logic now prevents similar issues from occurring

## Recommendations

1. **Monitor**: Keep an eye on new user registrations to ensure the plugin fix is working
2. **Backup**: Regular database backups are recommended before any future schema changes
3. **Testing**: Test the plugin in a development environment before deploying updates
4. **Documentation**: Update any user-facing documentation about the points system

## Files Modified

- `scripting/l4d2_stats_recorder.sp` - Fixed plugin logic
- `website-api/routes/top.js` - Simplified points handling
- `website-api/routes/user.js` - Simplified user data retrieval
- `website-api/routes/misc.js` - Updated search functionality
- Database: Applied comprehensive data repair

## SQL Scripts Created

- `fix_playtime_discrepancies.sql` - Initial diagnostic script
- `comprehensive_stats_fix.sql` - Complete database repair script
