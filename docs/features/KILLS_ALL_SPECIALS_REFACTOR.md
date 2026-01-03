# Kills All Specials Column Refactor

## Overview

The `kills_all_specials` column has been removed from both `stats_users` and `stats_map_users` tables to eliminate redundant data storage. Instead, this value is now calculated on-the-fly in API responses.

## Changes Made

### 1. Database Migration
- **File**: `database_migrations/drop_kills_all_specials_column.sql`
- **Action**: Dropped `kills_all_specials` column from both tables
- **Reason**: Avoid storing redundant calculated data

### 2. Helper Utility
- **File**: `website-api/utils/dataHelpers.js`
- **Functions**:
  - `addKillsAllSpecials()` - Adds calculated `kills_all_specials` field
  - `addSpecialInfectedKills()` - Adds calculated `special_infected_kills` field
- **Logic**: `kills_all_specials = kills_smoker + kills_boomer + kills_hunter + kills_spitter + kills_jockey + kills_charger`

### 3. API Endpoints Updated

#### Modified Files:
- `website-api/routes/user.js`
- `website-api/routes/maps.js` 
- `website-api/routes/misc.js`
- `website-api/routes/sessions.js`
- `website-api/services/DataValidator.js`

#### Specific Changes:

**User Endpoints:**
- `/api/user/random` - Added `kills_all_specials` calculation
- `/api/user/:user` - Added `kills_all_specials` calculation  
- `/api/user/:user/points/calculate` - Added `kills_all_specials` before point calculation

**Maps Endpoints:**
- `/api/maps/:mapid/users/:steamid/points/calculate` - Added `kills_all_specials` calculation
- `/api/maps/:mapid/users/:steamid/mvp/calculate` - Added `kills_all_specials` calculation

**Misc Endpoints:**
- `/api/recalculate` - Removed database update logic, added calculation before point processing

**Sessions Endpoints:**
- Already calculated `special_infected_kills` in SQL query (no changes needed)

### 4. Data Validation
- **File**: `website-api/services/DataValidator.js`
- **Change**: Removed `kills_all_specials` from validation fields list

## Implementation Details

### Calculation Logic
```javascript
const killsAllSpecials = (
    (userData.kills_smoker || 0) +
    (userData.kills_boomer || 0) +
    (userData.kills_hunter || 0) +
    (userData.kills_spitter || 0) +
    (userData.kills_jockey || 0) +
    (userData.kills_charger || 0)
);
```

### Usage Pattern
```javascript
// Before point calculation
const userWithSpecials = addKillsAllSpecials(userData);
const pointBreakdown = pointCalculator.calculateUserPoints(userWithSpecials);

// Before API response
const userWithSpecials = addKillsAllSpecials(userData);
res.json({ user: userWithSpecials });
```

## Benefits

1. **Data Consistency**: No risk of `kills_all_specials` being out of sync with individual kill counts
2. **Storage Efficiency**: Reduced database storage by eliminating redundant columns
3. **Maintainability**: Single source of truth for special kills calculation
4. **Backward Compatibility**: API responses remain unchanged for UI

## API Response Compatibility

All API endpoints continue to return `kills_all_specials` or `special_infected_kills` fields as before. The UI requires no changes.

### Example Response (unchanged):
```json
{
  "user": {
    "steamid": "STEAM_1:0:123456",
    "kills_smoker": 10,
    "kills_boomer": 8,
    "kills_hunter": 15,
    "kills_spitter": 5,
    "kills_jockey": 12,
    "kills_charger": 7,
    "kills_all_specials": 57  // ← Calculated on-the-fly
  }
}
```

## Migration Steps

1. **Run Migration**: Execute `drop_kills_all_specials_column.sql`
2. **Deploy Code**: Update API with new calculation logic
3. **Test**: Verify all endpoints return correct `kills_all_specials` values
4. **Monitor**: Check point calculations are still accurate

## Testing

Verify these endpoints return correct `kills_all_specials`:
- `GET /api/user/random`
- `GET /api/user/:steamid`
- `GET /api/user/:steamid/points/calculate`
- `GET /api/maps/:mapid/users/:steamid/points/calculate`
- `GET /api/maps/:mapid/users/:steamid/mvp/calculate`
- `POST /api/recalculate`

## Rollback Plan

If issues arise:
1. Re-add `kills_all_specials` columns to both tables
2. Run `/api/recalculate` to populate the columns
3. Revert API code changes

---

**Note**: This refactor improves data integrity while maintaining full API compatibility.
