# Point Calculation Issues - Technical Analysis

## Issue Summary

**Date**: 2025-01-16  
**Status**: Critical Issues Identified  
**Impact**: Point calculations are inaccurate due to missing data and plugin bugs

## Critical Issues

### 1. SourcePawn Plugin - Missing Special Kills Data

**Problem**: The `kills_all_specials` field is 0 for all players in both `stats_users` and `stats_map_users` tables.

**Root Cause**: 
- Plugin records individual special kills (`kills_smoker`, `kills_boomer`, etc.) correctly
- Plugin **NEVER updates** the `kills_all_specials` aggregate field
- Main stats update query (line 944 in `l4d2_stats_recorder.sp`) excludes special kill fields

**Evidence**:
```sql
-- Individual special kills exist:
SELECT steamid, kills_smoker, kills_boomer, kills_hunter FROM stats_users WHERE steamid = 'STEAM_1:1:50902447';
-- Result: 240, 188, 266 (total: 694 special kills)

-- But aggregate field is 0:
SELECT steamid, kills_all_specials FROM stats_users WHERE steamid = 'STEAM_1:1:50902447';
-- Result: 0
```

**Impact**: 
- Missing ~4,164 points for Anlv (694 × 6 = 4,164)
- All players lose significant points from special kills
- Rankings are completely inaccurate

### 2. Friendly Fire Penalty Not Applied Correctly

**Problem**: The -40 points per FF damage penalty is not being applied consistently.

**Expected vs Actual**:
```
Anlv FF Damage: 392
Expected Penalty: 392 × 40 = -15,680 points
Actual Points: 14,635 (should be much lower with penalty)
```

**Possible Causes**:
- Penalty calculation disabled in PointCalculator
- Wrong penalty value being used (-3 instead of -40)
- Field mapping issue with `survivor_ff` field
- Logic bug in penalty calculation

### 3. Tank Damage Points Inconsistency

**Problem**: Tank damage points (0.1 per damage) may not be applied consistently.

**Analysis**:
```
Anlv Tank Damage: 76,520
Expected Points: 76,520 × 0.1 = 7,652 points
```

**Status**: Recently disabled in configuration, but impact unclear.

## Data Analysis

### Current Point Values (After Recent Recalculation)

| Player | Overall Points | Map Points | Common Kills | Special Kills | FF Damage | Expected Points |
|--------|----------------|------------|--------------|---------------|-----------|-----------------|
| **Anlv** | 14,635 | 1,771 | 4,652 | 0 (should be 694) | 392 | ~2,054 with penalties |
| **wang** | 8,201 | 2,294 | 4,819 | 0 (should be 682) | 249 | ~4,662 with penalties |
| **Nusty** | 6,689 | 2,037 | 3,429 | 0 (should be 347) | 172 | ~4,516 with penalties |
| **GOD** | 2,702 | 980 | 3,749 | 0 (should be 347) | 222 | ~2,859 with penalties |

### Point Calculation Discrepancies

**Overall vs Map Points**:
- Anlv: 14,635 (overall) vs 1,771 (map) = 8.3x difference
- Suggests different calculation rules or data sources

**Missing Special Kill Points**:
- Total missing special kills across all players: ~2,070 kills
- Total missing points: ~12,420 points (2,070 × 6)

## Technical Root Causes

### 1. SourcePawn Plugin Issues

**File**: `scripting/l4d2_stats_recorder.sp`

**Missing Fields in Main Update Query (Line 944)**:
```c
// Current query excludes:
kills_smoker, kills_boomer, kills_hunter, kills_spitter, 
kills_jockey, kills_charger, kills_all_specials,
heal_others, revived_others, defibs_used
```

**Missing Aggregate Calculation**:
```c
// Need to add:
int totalSpecialKills = players[client].sBoomerKills + players[client].sSmokerKills + 
                       players[client].sHunterKills + players[client].sSpitterKills + 
                       players[client].sJockeyKills + players[client].sChargerKills;
```

### 2. Point System Configuration Issues

**File**: `website-api/config/point-system.json`

**Field Mapping Corrections Made**:
- `special_infected_kills` source_field: `special_infected_kills` → `kills_all_specials`
- `teammate_save` source_field: `special_infected_kills` → `kills_all_specials`

**Penalty Configuration**:
```json
// Main system (should be applied):
"friendly_fire_damage": {
  "points_per_damage": -40,
  "source_field": "survivor_ff"
}

// MVP system (different penalty):
"penalties": {
  "ff_damage_multiplier": -3
}
```

### 3. API Implementation Issues

**Recalculate API**: Working correctly but using incomplete data
**MVP Calculator**: May be using wrong data source or rules
**Point Calculator**: Penalty logic needs verification

## Required Fixes

### Priority 1: Fix SourcePawn Plugin

**File**: `scripting/l4d2_stats_recorder.sp`

1. **Add missing fields to main stats update query (line 944)**:
```c
kills_smoker=kills_smoker+%d,
kills_boomer=kills_boomer+%d,
kills_hunter=kills_hunter+%d,
kills_spitter=kills_spitter+%d,
kills_jockey=kills_jockey+%d,
kills_charger=kills_charger+%d,
kills_all_specials=kills_all_specials+%d,
heal_others=heal_others+%d,
revived_others=revived_others+%d,
defibs_used=defibs_used+%d
```

2. **Calculate kills_all_specials before update**:
```c
int totalSpecialKills = players[client].sBoomerKills + players[client].sSmokerKills + 
                       players[client].sHunterKills + players[client].sSpitterKills + 
                       players[client].sJockeyKills + players[client].sChargerKills;
```

3. **Update both stats_users and stats_map_users tables**

### Priority 2: Verify Point Calculation Logic

**File**: `website-api/services/PointCalculator.js`

1. **Test penalty calculation**:
```javascript
// Verify -40 FF penalty is applied
const ffPenalty = userData.survivor_ff * 40;
```

2. **Verify field mappings**:
```javascript
// Ensure source_field mappings work correctly
const specialKills = userData[config.source_field]; // should be userData.kills_all_specials
```

### Priority 3: Data Cleanup

1. **Recalculate kills_all_specials for existing data**:
```sql
UPDATE stats_users SET kills_all_specials = 
  kills_smoker + kills_boomer + kills_hunter + 
  kills_spitter + kills_jockey + kills_charger;

UPDATE stats_map_users SET kills_all_specials = 
  kills_smoker + kills_boomer + kills_hunter + 
  kills_spitter + kills_jockey + kills_charger;
```

2. **Run point recalculation after fixes**

## Testing Plan

### 1. Plugin Testing
- Deploy fixed plugin to test server
- Play test sessions and verify all fields are updated
- Check both stats_users and stats_map_users tables

### 2. Point Calculation Testing
- Test with known data sets
- Verify penalty calculations
- Compare manual calculations with API results

### 3. Integration Testing
- Test all three point calculation types
- Verify MVP calculations
- Test recalculation APIs

## Monitoring

### Key Metrics to Watch
- `kills_all_specials` field values (should not be 0)
- Point calculation accuracy
- Penalty application consistency
- Data consistency between tables

### Validation Queries
```sql
-- Check for missing special kills data
SELECT COUNT(*) FROM stats_users WHERE kills_all_specials = 0 AND (kills_smoker + kills_boomer + kills_hunter) > 0;

-- Verify point calculation accuracy
SELECT steamid, points, common_kills, kills_all_specials, survivor_ff FROM stats_users ORDER BY points DESC LIMIT 5;
```

---

**Next Steps**: 
1. Fix SourcePawn plugin
2. Test on development server
3. Deploy to production
4. Run data cleanup and recalculation
5. Monitor point accuracy

**Estimated Impact**: Fixing these issues will significantly change player rankings and point values.
