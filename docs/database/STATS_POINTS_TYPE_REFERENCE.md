# Stats Points Type Column Reference

## Overview

The `stats_points` table records individual point transactions for players in the L4D2 Stats Plugin. The `type` column uses numeric values to categorize different types of point-earning or point-losing actions.

## Database Schema

```sql
CREATE TABLE `stats_points` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `steamid` varchar(32) NOT NULL,
    `type` smallint(6) NOT NULL,           -- ← Point action type (0-13)
    `amount` smallint(6) NOT NULL,         -- ← Points gained/lost
    `timestamp` int(11) NOT NULL,          -- ← Unix timestamp
    `mapId` varchar(32) DEFAULT NULL,      -- ← Map where action occurred
    PRIMARY KEY (`id`),
    KEY `stats_points_stats_users_steamid_fk` (`steamid`),
    KEY `stats_points_timestamp_index` (`timestamp`),
    KEY `idx_stats_points_mapId` (`mapId`)
);
```

## Point Type Definitions

The `type` column corresponds to the `PointRecordType` enum defined in the SourcePawn plugin:

### Base Point Types (0-25)

| Type | Enum Name | Display Name | Description | Typical Amount |
|------|-----------|--------------|-------------|----------------|
| 0 | `PType_Generic` | Generic | General/miscellaneous points | Variable |
| 1 | `PType_FinishCampaign` | Finish Campaign | Completing a campaign/finale | +1000 |
| 2 | `PType_CommonKill` | Common Kill | Killing common infected | +1 |
| 3 | `PType_SpecialKill` | Special Kill | Killing special infected | +6 |
| 4 | `PType_TankKill` | Tank Kill | Killing a Tank (damage-based) | +1-100 |
| 5 | `PType_WitchKill` | Witch Kill | Killing a Witch | +15 |
| 6 | `PType_TankKill_Solo` | Solo Tank Kill | Killing Tank without team help | +20 |
| 7 | `PType_TankKill_Melee` | Melee-Only Tank Kill | Killing Tank with melee only | +50 |
| 8 | `PType_Headshot` | Headshot | Headshot kills | +2 |
| 9 | `PType_FriendlyFire` | Friendly Fire Penalty | Damaging teammates | -30 |
| 10 | `PType_HealOther` | Healing Teammate | Healing other players | +40-60 |
| 11 | `PType_ReviveOther` | Reviving Teammate | Reviving incapacitated players | +25 |
| 12 | `PType_ResurrectOther` | Defibbing Teammate | Using defibrillator on dead players | +50 |
| 13 | `PType_DeployAmmo` | Deploying Ammo | Deploying ammo packs | +20 |
| 14 | `PType_WitchCrown` | Witch Crown | Crowning a witch (one-shot kill) | +25 |
| 15 | `PType_MeleeKill` | Melee Kill | Killing with melee weapons | +1 |
| 16 | `PType_PillUse` | Pills Used | Using pain pills | +10 |
| 17 | `PType_AdrenalineUse` | Adrenaline Used | Using adrenaline shots | +15 |
| 18 | `PType_MolotovUse` | Molotov Used | Throwing molotov cocktails | +5 |
| 19 | `PType_PipeUse` | Pipe Bomb Used | Throwing pipe bombs | +5 |
| 20 | `PType_BileUse` | Bile Bomb Used | Throwing bile bombs | +5 |
| 21 | `PType_TankDamage` | Tank Damage | Individual tank damage points | Variable |
| 22 | `PType_ClearPinned` | Cleared Pinned Teammate | Saving pinned teammates | +15 |
| 23 | `PType_SmokerSelfClear` | Smoker Self Clear | Self-clearing from smokers | +10 |
| 24 | `PType_HunterDeadstop` | Hunter Deadstop | Deadstopping hunters | +20 |
| 25 | `PType_BoomerBileHit` | Boomer Bile Hit | Bile hits on enemies | +3 |

### Penalty Point Types (26-32)

| Type | Enum Name | Display Name | Description | Typical Amount |
|------|-----------|--------------|-------------|----------------|
| 26 | `PType_Death` | Death Penalty | Dying as survivor | -10 |
| 27 | `PType_CarAlarm` | Car Alarm Penalty | Triggering car alarms | -10 |
| 28 | `PType_TimesPinned` | Pinned Penalty | Getting pinned by special infected | -5 |
| 29 | `PType_TankRockHit` | Tank Rock Hit Penalty | Getting hit by tank rocks | -10 |
| 30 | `PType_ClownHonk` | Clown Honk Penalty | Honking clowns | -5 |
| 31 | `PType_BoomerBileSelf` | Boomer Bile Self Penalty | Getting biled by boomer | -5 |
| 32 | `PType_TeammateKill` | Teammate Kill Penalty | Killing teammates | -500 |

## Special Cases

### Friendly Fire (Type 9) - Individual Damage Recording

The friendly fire system now records individual damage instances:

| Type | Amount | Description | Trigger |
|------|--------|-------------|---------|
| 9 | -30 | Friendly Fire Damage | Each HP damage dealt to teammate |
| 32 | -500 | Teammate Kill | Killing a teammate |

**Note**: Each point of friendly fire damage now creates a separate transaction record for complete audit trail.

### Heal Others (Type 10) - Variable Points

Healing points vary based on target's health condition:

| Amount | Description | Trigger |
|--------|-------------|---------|
| +60 | Critical Heal | Healing teammate with ≤25% health |
| +40 | Standard Heal | Healing teammate with 26-75% health |
| 0 | No Points | Healing teammate with >75% health |

## Usage in Code

### SourcePawn Plugin (Recording)
```sourcepawn
// Recording points in l4d2_stats_recorder.sp
void RecordPoint(PointRecordType type, int amount = 1) {
    this.points += amount;
    int index = this.pointsQueue.Push(type);
    this.pointsQueue.Set(index, amount, 1);
    this.pointsQueue.Set(index, GetTime(), 2);
}

// Database insertion
Format(query, sizeof(query), "INSERT INTO stats_points (steamid,type,amount,timestamp,mapId) VALUES ");
```

### Frontend Display (Vue.js)
```javascript
// Display mapping in website-ui/src/components/user/points.vue
const POINT_TYPE_DISPLAY = [
  "Generic",                    // 0
  "Finish Campaign",            // 1
  "Common Kill",                // 2
  "Special Kill",               // 3
  "Tank Kill",                  // 4
  "Witch Kill",                 // 5
  "Solo Tank Kill",             // 6
  "Melee-Only Tank Kill",       // 7
  "Headshot",                   // 8
  "Friendly Fire Penalty",      // 9
  "Healing Teammate",           // 10
  "Reviving Teammate",          // 11
  "Defibbing Teammate",         // 12
  "Deploying Ammo"              // 13
]
```

### API Usage
```javascript
// Fetching points history in website-api/routes/user.js
router.get('/:user/points/:page', async (req,res) => {
    const [rows] = await pool.query(
        "SELECT timestamp, type, amount FROM stats_points WHERE steamid = ? ORDER BY id DESC LIMIT ?,?", 
        [req.params.user, offset, perPage]
    );
});
```

## Important Notes

1. **Real-time Recording**: Points are recorded immediately when actions occur in-game
2. **Complete Audit Trail**: This table now maintains individual transactions for ALL 33 point types
3. **Map Context**: Each point record includes the `mapId` where the action occurred
4. **Expanded Coverage**: System now covers every rule defined in `point-system.json`
5. **Penalty Types**: Types 9, 26-32 typically have negative amounts as penalties
6. **Queue System**: Points are queued in the plugin and batch-inserted to the database
7. **User Validation**: The plugin ensures users exist in `stats_users` before inserting points
8. **Backward Compatibility**: Existing types 0-13 remain unchanged for compatibility

## Related Tables

- **`stats_users`**: Contains cumulative point totals (`points` column)
- **`stats_map_users`**: Contains session-based statistics for MVP calculations
- **`map_info`**: Referenced by `mapId` foreign key

## Configuration

Point amounts are configurable via `website-api/config/point-system.json`:
- Base point values for each action type
- Penalty multipliers for friendly fire
- Special bonuses and multipliers
- MVP calculation rules

## Queries Examples

### Get player's point history
```sql
SELECT timestamp, type, amount, mapId 
FROM stats_points 
WHERE steamid = 'STEAM_1:0:12345' 
ORDER BY timestamp DESC;
```

### Get friendly fire incidents
```sql
SELECT steamid, amount, timestamp, mapId 
FROM stats_points 
WHERE type = 9 AND amount < 0 
ORDER BY timestamp DESC;
```

### Get top point earners by action type
```sql
SELECT steamid, SUM(amount) as total_points
FROM stats_points
WHERE type = 4 AND amount > 0  -- Tank kills only
GROUP BY steamid
ORDER BY total_points DESC;
```

### Get witch crown achievements
```sql
SELECT steamid, COUNT(*) as witch_crowns, SUM(amount) as total_points
FROM stats_points
WHERE type = 14  -- PType_WitchCrown
GROUP BY steamid
ORDER BY witch_crowns DESC;
```

### Get penalty summary for a player
```sql
SELECT type, COUNT(*) as occurrences, SUM(amount) as total_penalty
FROM stats_points
WHERE steamid = 'STEAM_1:0:12345' AND amount < 0
GROUP BY type
ORDER BY total_penalty ASC;
```
