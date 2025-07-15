# Homepage Points Display Fix

## Issue Description

The homepage leaderboard (`/top`) was displaying incorrect points values that didn't match the user detail pages.

## Root Cause Analysis

### The Problem
The `/api/top/users` endpoint had two versions:
- **Version 1**: Used database points directly (correct)
- **Version 2**: Used old calculated points formula (incorrect after database repair)

**By default**, the frontend was using **Version 2** with the outdated calculation formula, while user detail pages were showing the correct database points.

### Database Verification
**Current Database Points (Correct):**
```
User        | Database Points
----------- | ---------------
BuiQuang    | 676
Nusty       | 527  
dOnNie      | 441
longlaotam  | 240
Tyrion      | 135
```

**Old V2 Calculation (Incorrect):**
```
User        | Old V2 Calc
----------- | ------------
BuiQuang    | 21.77
Nusty       | 13.45
dOnNie      | 11.76
longlaotam  | 2.82
Tyrion      | -1.55 (negative!)
```

### Frontend Behavior
In `website-ui/src/views/Leaderboard.vue` line 166:
```javascript
const params = this.$route.query.version ? `?version=${this.$route.query.version}` : ""
return this.$http.get(`/api/top/users/${this.top_page}${params}`, { cache: true })
```

- **Default** (no version param): Used Version 2 (incorrect old calculation)
- **With `?version=1`**: Used Version 1 (correct database points)

## Solution Applied

### API Endpoint Fix
**File**: `website-api/routes/top.js`

**Changed the default behavior:**
- **Before**: Default = Version 2 (old calculation), `?version=1` = Database points
- **After**: Default = Version 1 (database points), `?version=2` = Old calculation (legacy)

**Implementation:**
```javascript
if(req.query.version == "2") {
    // Legacy v2 calculated points (kept for compatibility)
    [rows] = await pool.query(`select ... (old calculation formula)`, [offset, MAX_RESULTS])
    version = "v2"
} else {
    // Default: Use corrected database points (v1)
    [rows] = await pool.query("SELECT steamid,last_alias,minutes_played,last_join_date,points FROM `stats_users` ORDER BY `points` DESC, `minutes_played` DESC LIMIT ?,?", [offset, MAX_RESULTS])
    version = "v1"
}
```

## Benefits

### 1. **Consistency**
- Homepage leaderboard now shows the same points as user detail pages
- No more confusion between different point values

### 2. **Accuracy**
- Points reflect the corrected database values from the comprehensive repair
- Users see their actual earned points based on the improved formula

### 3. **Backward Compatibility**
- Legacy v2 calculation still available via `?version=2` parameter
- No breaking changes for any existing bookmarks or links

### 4. **User Experience**
- Users will see consistent point values across the entire application
- Leaderboard rankings now reflect the corrected point system

## Testing

### Before Fix
```bash
# Homepage leaderboard (incorrect)
curl http://localhost:3000/api/top/users/1
# Would show: BuiQuang with ~22 points

# User detail page (correct)  
curl http://localhost:3000/api/user/BuiQuang
# Would show: BuiQuang with 676 points
```

### After Fix
```bash
# Homepage leaderboard (now correct)
curl http://localhost:3000/api/top/users/1
# Now shows: BuiQuang with 676 points

# User detail page (still correct)
curl http://localhost:3000/api/user/BuiQuang  
# Still shows: BuiQuang with 676 points

# Legacy calculation (if needed)
curl http://localhost:3000/api/top/users/1?version=2
# Shows old calculation: BuiQuang with ~22 points
```

## Impact Assessment

### Users Affected
- **All users**: Will see consistent points across homepage and detail pages
- **High-point users**: Will see significantly higher (and more accurate) point values
- **Tyrion specifically**: Will see 135 points instead of negative points

### UI Changes
- **Homepage leaderboard**: Points values will increase significantly to match corrected values
- **User rankings**: May change based on corrected point calculations
- **No visual changes**: Same UI, just correct data

## Verification Steps

1. **Check Homepage Consistency**:
   - Visit homepage leaderboard
   - Click on a user to view their detail page
   - Verify points match between both views

2. **Verify Top Users**:
   - Confirm BuiQuang shows 676 points (not ~22)
   - Confirm Tyrion shows 135 points (not negative)
   - Verify ranking order is consistent

3. **Test Legacy Support**:
   - Add `?version=2` to leaderboard URL
   - Confirm it shows old calculation values
   - Verify default (no param) shows corrected values

## Files Modified

- `website-api/routes/top.js`: Fixed default version behavior
- `HOMEPAGE_POINTS_FIX.md`: Documentation of the fix

## Related Issues

This fix complements the previous comprehensive database repair from PR #1:
- **PR #1**: Fixed database points calculation and playtime tracking
- **This Fix**: Ensures homepage displays the corrected database points

## Future Recommendations

1. **Monitor**: Watch for any user confusion about point changes
2. **Consider**: Eventually removing the legacy v2 calculation option
3. **Document**: Update any user-facing documentation about the points system
4. **Test**: Verify all leaderboard-related features work correctly

## Conclusion

This fix ensures complete consistency across the L4D2 stats application. Users will now see the same, correct point values whether they're viewing the homepage leaderboard or individual user detail pages. The fix maintains backward compatibility while making the corrected points system the default experience.
