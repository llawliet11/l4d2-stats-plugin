# Recalculate API Enhancement

## Overview

The `/api/recalculate` endpoint has been enhanced to recalculate points for both overall user statistics (`stats_users`) and map-specific statistics (`stats_map_users`).

## What's New

### Before Enhancement
- ✅ Recalculated points for `stats_users` table (overall rankings)
- ✅ Updated `kills_all_specials` for both tables
- ❌ Did NOT recalculate points for `stats_map_users` table

### After Enhancement
- ✅ Recalculates points for `stats_users` table (overall rankings)
- ✅ Updates `kills_all_specials` for both tables
- ✅ **NEW: Recalculates points for `stats_map_users` table (map-specific rankings)**

## Technical Implementation

### API Endpoint
`POST /api/recalculate`

### Process Flow
1. **Initialize PointCalculator** with current `point-system.json` configuration
2. **Update derived fields** (`kills_all_specials`) in both tables
3. **Process overall user points**:
   - Get all users from `stats_users`
   - Calculate points using `pointCalculator.calculateSessionPoints()`
   - Update `stats_users.points` field
4. **Process map-specific points** (NEW):
   - Get all map-user combinations from `stats_map_users`
   - Calculate points using `pointCalculator.calculateMapPoints()`
   - Update `stats_map_users.points` field by `steamid` and `mapid`

### Batch Processing
- **Overall users**: 100 users per batch
- **Map-users**: 50 combinations per batch (smaller for performance)

### Error Handling
- Individual map-user calculation errors don't stop the entire process
- Detailed logging for debugging
- Comprehensive error reporting

## Response Format

```json
{
  "success": true,
  "message": "Points recalculated successfully for both overall and map-specific statistics",
  "stats": {
    "users_processed": 150,
    "total_points_calculated": 45000,
    "map_users_processed": 1200,
    "total_map_points_calculated": 38000,
    "overall_stats": {
      "total_users": 150,
      "total_points": 45000,
      "avg_points": 300,
      "max_points": 2500
    },
    "map_stats": {
      "total_map_users": 1200,
      "total_map_points": 38000,
      "avg_map_points": 31.67,
      "max_map_points": 850
    }
  }
}
```

## UI Enhancement

The success toast message now shows statistics for both:
- Overall user points recalculation
- Map-specific points recalculation

## Performance Considerations

- **Batch processing** prevents memory issues with large datasets
- **Smaller batch size** for map calculations due to higher complexity
- **Error isolation** ensures one failed calculation doesn't break the entire process
- **Progress logging** for monitoring long-running operations

## Use Cases

This enhancement ensures that:
1. **Overall leaderboards** (`/api/top/users`) show correct points
2. **Map-specific leaderboards** show correct points for individual maps
3. **Campaign statistics** reflect accurate point calculations
4. **MVP calculations** for maps use correct base points

## Related Endpoints

After recalculation, these endpoints will show updated points:
- `GET /api/top/users` - Overall rankings
- `GET /api/maps/:mapid/users/:steamid/points/calculate` - Map-specific points
- `GET /api/campaigns/:campaignId` - Campaign statistics
- `GET /api/mvp/map/:mapId` - Map MVP calculations

## Configuration

Points calculation rules are defined in:
- `website-api/config/point-system.json`

The same rules apply to both overall and map-specific calculations, ensuring consistency across the system.

## Logging

Enhanced logging includes:
- Progress updates for both user and map-user processing
- Error details for failed calculations
- Summary statistics upon completion
- Debug information for first few processed items

---

**Note**: This enhancement ensures complete consistency between stored points and the point calculation system defined in `point-system.json`.
