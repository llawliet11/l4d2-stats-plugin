# L4D2 Stats Plugin - Point Calculation System

## Overview

The L4D2 Stats Plugin implements a **four-tier point calculation system** to provide different types of player rankings and achievements. Each tier serves a specific purpose and uses different data sources and calculation rules.

## 🚨 **CRITICAL PRINCIPLE: Configuration-Driven System**

**ALL calculations MUST strictly follow `point-system.json` configuration.**
- ❌ **No hardcoded values** in any calculation code
- ✅ **All penalties, points, and rules** loaded from configuration file
- 🔄 **Runtime configuration changes** supported (restart API to reload)
- 🎛️ **Complete flexibility** to adjust any rule without code changes

## Four-Tier Architecture

### 1. Overall Points (Global Rankings)
- **Data Source**: `stats_users` table
- **Scope**: Cumulative stats across ALL maps and campaigns
- **Purpose**: Global leaderboards, lifetime player rankings
- **Configuration**: Uses main `point-system.json` → `penalties.friendly_fire_damage.points_per_damage`
- **Current Penalty**: **FF × -40** (configurable in point-system.json)
- **API Endpoint**: `/api/users/` (leaderboard)

### 2. Map Points (Map-Specific Rankings)
- **Data Source**: `stats_map_users` table
- **Scope**: Stats filtered by specific `mapId`
- **Purpose**: Map-specific leaderboards and rankings
- **Configuration**: Uses main `point-system.json` → `penalties.friendly_fire_damage.points_per_damage`
- **Current Penalty**: **FF × -40** (configurable in point-system.json)
- **API Endpoint**: `/api/maps/{mapId}/users/`

### 3. MVP All Time (Global Champion)
- **Data Source**: `stats_users` table (lifetime stats)
- **Scope**: Best player across ALL maps and campaigns
- **Purpose**: Overall champion recognition, global MVP
- **Configuration**: Uses `point-system.json` → `mvp_calculation.point_values.penalties.ff_damage_multiplier`
- **Current Penalty**: **FF × -3** (configurable in point-system.json)
- **API Endpoint**: `/api/mvp/global`

### 4. MVP of Map (Map Champion)
- **Data Source**: `stats_map_users` table (filtered by mapId)
- **Scope**: Best player for a specific map/campaign
- **Purpose**: Map-specific champion recognition
- **Configuration**: Uses `point-system.json` → `mvp_calculation.point_values.penalties.ff_damage_multiplier`
- **Current Penalty**: **FF × -3** (configurable in point-system.json)
- **API Endpoint**: `/api/mvp/map/{mapId}`

## Database Tables

### stats_users (Overall Stats)
```sql
-- Cumulative lifetime stats across all maps
steamid, last_alias, common_kills, kills_all_specials, 
survivor_ff, heal_others, revived_others, defibs_used,
damage_to_tank, kills_witch, witches_crowned, finales_won,
minutes_played, last_join_date, points
```

### stats_map_users (Map-Specific Stats)
```sql
-- Aggregated stats per player per map
steamid, mapid, common_kills, kills_all_specials,
survivor_ff, heal_others, revived_others, defibs_used,
damage_to_tank, kills_witch, witches_crowned, finales_won,
points
```

### stats_games (Individual Sessions)
```sql
-- Individual game session records
-- Used for detailed session analysis and MVP calculation
```

## Point Calculation Rules

### Main Point System (Overall & Map Points)
**Configuration**: `point-system.json` → `base_points` and `penalties` sections
**Used For**: Overall rankings and map-specific rankings

**Positive Actions**:
- Common kills: 1 point each
- Special infected kills: 6 points each
- Heal teammates: 40 points each
- Revive teammates: 25 points each
- Defibrillator use: 30 points each
- Tank damage: 0.1 points per damage (currently disabled)
- Witch kills: 15 points each
- Finale completion: 1000 points each

**Penalties** (Configurable in point-system.json):
- Friendly fire damage: **Current: -40 points per HP damage** (configurable)
- Teammate kills: **Current: -500 points each** (configurable)
- Deaths: **Current: -50 points each** (currently disabled via config)

### MVP Calculation System (Both Global & Map MVP)
**Configuration**: `point-system.json` → `mvp_calculation.point_values` section
**Used For**: MVP All Time and MVP of Map determinations

**Positive Actions**:
- Common kills: 1 point each
- Special kills: 6 points each
- Tank kill: up to 100 points
- Witch kills: 15 points each
- Heal teammates: 40 points each
- Revive teammates: 25 points each
- Defibrillator use: 30 points each
- Finale win: 1000 points each
- Item usage: 5-15 points each

**Penalties** (Configurable in point-system.json):
- Teammate kills: **Current: -100 points each** (configurable)
- Friendly fire damage: **Current: -3 multiplier** (configurable)

**Design Rationale**: Current configuration uses lighter penalties for MVP determination to focus more on positive contributions. **All values are configurable and can be changed in point-system.json.**

**Tie-Breaking Criteria** (when MVP points are equal):
1. Special Infected Kills (highest)
2. Friendly Fire Count (lowest)
3. Common Infected Kills (highest)
4. Damage Taken (lowest)
5. Friendly Fire Damage (lowest)

## Configuration Management

### 🎛️ **All Rules Are Configurable**

**File**: `website-api/config/point-system.json`

**To Change Any Penalty or Point Value:**
1. Edit `point-system.json`
2. Restart API: `docker-compose restart l4d2stats-api`
3. Run recalculation: `/api/recalculate`

### Configuration Structure
```json
{
  "base_points": {
    "common_kills": {
      "points_per_kill": 1,           // ← Configurable
      "source_field": "common_kills"
    },
    "special_infected_kills": {
      "points_per_kill": 6,           // ← Configurable
      "source_field": "kills_all_specials"
    }
  },
  "penalties": {
    "friendly_fire_damage": {
      "points_per_damage": -40,       // ← Change Overall/Map FF penalty here
      "source_field": "survivor_ff"
    }
  },
  "mvp_calculation": {
    "point_values": {
      "positive_actions": { /* Same as base_points */ },
      "penalties": {
        "ff_damage_multiplier": -3    // ← Change MVP FF penalty here
      }
    },
    "ranking_criteria": { /* Tie-breaking rules */ }
  }
}
```

### 🔧 **Common Configuration Changes**

**Change Overall FF Penalty** (affects rankings):
```json
"penalties": {
  "friendly_fire_damage": {
    "points_per_damage": -50  // Changed from -40 to -50
  }
}
```

**Change MVP FF Penalty** (affects MVP determination):
```json
"mvp_calculation": {
  "point_values": {
    "penalties": {
      "ff_damage_multiplier": -5  // Changed from -3 to -5
    }
  }
}
```

**Enable/Disable Rules**:
```json
"tank_damage": {
  "points_per_damage": 0.1,
  "enabled": false,  // ← Disable this rule
  "note": "Temporarily disabled"
}
```

## System Integration

### Data Sources
- **Overall Rankings**: Uses `stats_users` table with main point system rules
- **Map Rankings**: Uses `stats_map_users` table with main point system rules
- **Global MVP**: Uses `stats_users` table with MVP calculation rules
- **Map MVP**: Uses `stats_map_users` table with MVP calculation rules

### Calculation Triggers
- **Real-time**: Points calculated during gameplay by SourcePawn plugin
- **Recalculation**: Manual recalculation available for rule changes
- **Validation**: Regular consistency checks ensure accuracy
- **Updates**: Configuration changes require API restart and recalculation

## Current Issues & Status

### ✅ Working Correctly
- Overall point calculation architecture
- Map-specific point separation
- MVP tie-breaking logic
- Point configuration system

### 🚨 Known Issues
1. **SourcePawn Plugin Bug**: `kills_all_specials` field is 0 for all players
2. **Missing Fields**: Plugin doesn't update special kill fields in main stats query
3. **Penalty Inconsistency**: -40 FF penalty may not be applied correctly
4. **Field Mapping**: Some source_field mappings need verification

### 🔧 Required Fixes
1. **Fix SourcePawn Plugin** (Priority 1)
   - Add missing fields to main stats update query
   - Calculate and update `kills_all_specials` field
   - Ensure all three tables get proper data

2. **Verify Point Calculations** (Priority 2)
   - Test -40 FF penalty application
   - Verify MVP vs main point system separation
   - Ensure correct data source usage

3. **Documentation Updates** (Priority 3)
   - Document field mappings
   - Create troubleshooting guides
   - Add configuration examples

## Example Point Calculations

### Overall Points Example (Anlv) - Main System with FF × -40
```
+ Common kills: 4,652 × 1 = 4,652
+ Special kills: 0 × 6 = 0 (BUG: should be ~694 × 6 = 4,164)
+ Heal others: 52 × 40 = 2,080
+ Revived others: 85 × 25 = 2,125
+ Tank damage: 76,520 × 0.1 = 7,652 (if enabled)
+ Witch kills: 9 × 15 = 135
+ Finales: 1 × 1000 = 1,000
- FF damage: 392 × 40 = -15,680 (harsh penalty for ranking)
= Expected: ~2,054 (with penalties) or ~17,734 (without penalties)
= Actual: 14,635 (suggests partial penalty application)
```

### Map Points Example (Anlv on requiem_05) - Main System with FF × -40
```
+ Common kills: 4,652 × 1 = 4,652
+ Heal others: 52 × 40 = 2,080
+ Revived others: 85 × 25 = 2,125
- FF damage: 392 × 40 = -15,680 (harsh penalty for ranking)
= Expected: ~-8,823 (with penalties) or ~8,857 (without penalties)
= Actual: 1,771 (suggests different calculation or data)
```

### MVP All Time Example (Anlv) - MVP System with FF × -3
```
+ Common kills: 4,652 × 1 = 4,652
+ Special kills: 694 × 6 = 4,164 (when fixed)
+ Heal others: 52 × 40 = 2,080
+ Revived others: 85 × 25 = 2,125
+ Tank kill bonus: up to 100 = 100
+ Witch kills: 9 × 15 = 135
+ Finales: 1 × 1000 = 1,000
- FF damage: 392 × 3 = -1,176 (lighter penalty for MVP)
= Expected: ~13,080 (much higher due to lighter penalty)
```

### MVP of Map Example (Anlv on requiem_05) - MVP System with FF × -3
```
+ Common kills: 4,652 × 1 = 4,652
+ Special kills: 694 × 6 = 4,164 (when fixed)
+ Heal others: 52 × 40 = 2,080
+ Revived others: 85 × 25 = 2,125
- FF damage: 392 × 3 = -1,176 (lighter penalty for MVP)
= Expected: ~11,845 (much higher than map points due to lighter penalty)
```

### Penalty System Comparison
| System | FF Penalty | Purpose | Anlv's FF Impact |
|--------|------------|---------|------------------|
| **Main Points** | 392 × 40 = **-15,680** | Harsh ranking penalty | Severe impact on ranking |
| **MVP System** | 392 × 3 = **-1,176** | Focus on positive play | Minimal impact on MVP status |

## Maintenance

### Regular Tasks
- Monitor point calculation accuracy
- Verify data consistency across tables
- Update configuration as needed
- Test recalculation APIs

### Troubleshooting
- Check plugin logs for stat recording issues
- Verify database field mappings
- Test point calculations manually
- Compare expected vs actual point values

---

**Last Updated**: 2025-01-16
**Version**: 1.0
**Status**: Documentation Complete, Implementation Issues Identified
