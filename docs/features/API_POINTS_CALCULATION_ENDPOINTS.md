# Points Calculation API Endpoints

This document describes the newly implemented API endpoints for calculating points overall and points per map in the L4D2 Stats system.

## Overview

The L4D2 Stats system now provides comprehensive points calculation APIs that leverage the `PointCalculator` service to compute points based on different data sources:

- **Overall User Points**: Based on lifetime statistics from `stats_users` table
- **Map-Specific Points**: Based on session data from `stats_map_users` table  
- **MVP Points**: Special MVP calculations for both overall and map-specific scenarios

## Database Tables Used

- **`stats_users`**: Lifetime user statistics with aggregated data
- **`stats_map_users`**: Map-specific session data for individual gameplay sessions
- **`stats_points`**: Historical point transactions and changes
- **`map_info`**: Map metadata for validation

## New API Endpoints

### 1. Overall User Points Calculation

**Endpoint**: `GET /api/users/:steamid/points/calculate`

**Description**: Calculates points for a user based on their lifetime statistics from the `stats_users` table.

**Parameters**:
- `steamid` (path): Steam ID of the user

**Response**:
```json
{
  "success": true,
  "steamid": "76561198000000000",
  "calculation_type": "user_overall",
  "breakdown": {
    "base_points": { /* detailed breakdown */ },
    "penalties": { /* penalty breakdown */ },
    "multipliers": { /* multiplier breakdown */ },
    "special_bonuses": { /* bonus breakdown */ },
    "total": 1250,
    "details": ["Common kills: 1000 × 1 = +1000", "..."],
    "data_source": "stats_users"
  },
  "user_data": {
    "steamid": "76561198000000000",
    "last_alias": "PlayerName",
    "points": 1250,
    "minutes_played": 3600
  }
}
```

**Cache**: 120 seconds

---

### 2. Map-Specific Points Calculation

**Endpoint**: `GET /api/maps/:mapid/users/:steamid/points/calculate`

**Description**: Calculates points for a user on a specific map based on session data from the `stats_map_users` table.

**Parameters**:
- `mapid` (path): Map ID
- `steamid` (path): Steam ID of the user
- `session_start` (query, optional): Specific session timestamp. If not provided, uses the most recent session.

**Response**:
```json
{
  "success": true,
  "steamid": "76561198000000000",
  "mapid": "c1m1_hotel",
  "calculation_type": "map_specific",
  "breakdown": {
    "base_points": { /* detailed breakdown */ },
    "penalties": { /* penalty breakdown */ },
    "multipliers": { /* multiplier breakdown */ },
    "special_bonuses": { /* bonus breakdown */ },
    "total": 450,
    "details": ["Common kills: 150 × 1 = +150", "..."],
    "data_source": "stats_map_users"
  },
  "map_data": {
    "steamid": "76561198000000000",
    "mapid": "c1m1_hotel",
    "map_name": "The Hotel",
    "last_alias": "PlayerName",
    "points": 450,
    "session_start": 1642780800,
    "session_end": 1642784400
  }
}
```

**Cache**: 120 seconds

---

### 3. Overall MVP Points Calculation

**Endpoint**: `GET /api/users/:steamid/mvp/calculate`

**Description**: Calculates MVP points for a user based on their lifetime statistics using specialized MVP calculation rules.

**Parameters**:
- `steamid` (path): Steam ID of the user

**Response**:
```json
{
  "success": true,
  "steamid": "76561198000000000",
  "calculation_type": "mvp_overall",
  "breakdown": {
    "positive_actions": { /* MVP positive actions */ },
    "penalties": { /* MVP penalties */ },
    "bonuses": { /* MVP bonuses */ },
    "total": 850,
    "details": ["Revives: 50 × 10 = +500", "..."],
    "calculation_type": "overall",
    "data_source": "stats_users"
  },
  "user_data": {
    "steamid": "76561198000000000",
    "last_alias": "PlayerName",
    "points": 1250,
    "minutes_played": 3600
  }
}
```

**Cache**: 120 seconds

---

### 4. Map-Specific MVP Points Calculation

**Endpoint**: `GET /api/maps/:mapid/users/:steamid/mvp/calculate`

**Description**: Calculates MVP points for a user on a specific map using specialized MVP calculation rules.

**Parameters**:
- `mapid` (path): Map ID
- `steamid` (path): Steam ID of the user
- `session_start` (query, optional): Specific session timestamp. If not provided, uses the most recent session.

**Response**:
```json
{
  "success": true,
  "steamid": "76561198000000000",
  "mapid": "c1m1_hotel",
  "calculation_type": "mvp_map",
  "breakdown": {
    "positive_actions": { /* MVP positive actions */ },
    "penalties": { /* MVP penalties */ },
    "bonuses": { /* MVP bonuses */ },
    "total": 320,
    "details": ["Revives: 5 × 10 = +50", "..."],
    "calculation_type": "map",
    "data_source": "stats_map_users"
  },
  "map_data": {
    "steamid": "76561198000000000",
    "mapid": "c1m1_hotel",
    "map_name": "The Hotel",
    "last_alias": "PlayerName",
    "points": 450,
    "session_start": 1642780800,
    "session_end": 1642784400
  }
}
```

**Cache**: 120 seconds

## Error Responses

All endpoints return consistent error responses:

```json
{
  "success": false,
  "message": "Error description"
}
```

Common error scenarios:
- **404**: User not found, Map not found, No session data found
- **500**: Internal server error, Point calculation failure

## Implementation Details

### Files Modified

1. **`website-api/routes/user.js`**:
   - Added `PointCalculator` import
   - Added `/users/:steamid/points/calculate` endpoint
   - Added `/users/:steamid/mvp/calculate` endpoint

2. **`website-api/routes/maps.js`**:
   - Added `PointCalculator` import
   - Added `/maps/:mapid/users/:steamid/points/calculate` endpoint
   - Added `/maps/:mapid/users/:steamid/mvp/calculate` endpoint

### Key Features

- **Caching**: All endpoints use 120-second cache for performance
- **Data Source Flexibility**: Supports both lifetime (`stats_users`) and session-specific (`stats_map_users`) data
- **Session Selection**: Map endpoints support querying specific sessions via `session_start` parameter
- **Comprehensive Breakdown**: Detailed point calculation breakdown with explanations
- **Error Handling**: Robust error handling with meaningful error messages
- **Validation**: Map and user existence validation before calculation

### Usage Examples

```bash
# Calculate overall points for a user
curl "http://localhost:3000/api/users/76561198000000000/points/calculate"

# Calculate points for a user on a specific map (latest session)
curl "http://localhost:3000/api/maps/c1m1_hotel/users/76561198000000000/points/calculate"

# Calculate points for a specific session
curl "http://localhost:3000/api/maps/c1m1_hotel/users/76561198000000000/points/calculate?session_start=1642780800"

# Calculate MVP points for overall stats
curl "http://localhost:3000/api/users/76561198000000000/mvp/calculate"

# Calculate MVP points for map-specific stats
curl "http://localhost:3000/api/maps/c1m1_hotel/users/76561198000000000/mvp/calculate"
```

## Related Endpoints

These new endpoints complement the existing points-related APIs:

- `GET /api/point-system` - Point system configuration
- `GET /api/point-breakdown/:sessionId` - Session-specific point breakdown
- `GET /api/users/:steamid/points/:page` - User point history
- `GET /api/top/users` - Top users by points
- `POST /api/recalculate` - Recalculate all user points
