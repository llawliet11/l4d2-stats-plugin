# Point Type và Point System Mapping

## Overview

Tài liệu này mapping giữa `PointRecordType` enum trong SourcePawn plugin và các rules trong `point-system.json` để đảm bảo consistency và dễ dàng maintenance.

## Complete Mapping Table

| Type | Enum Name | Point-System Rule | Points | Source Field | Status |
|------|-----------|-------------------|--------|--------------|--------|
| 0 | `PType_Generic` | N/A | Variable | N/A | ✅ Active |
| 1 | `PType_FinishCampaign` | `finale_win` | +1000 | `finales_won` | ✅ Active |
| 2 | `PType_CommonKill` | `common_kills` | +1 | `common_kills` | ✅ Active |
| 3 | `PType_SpecialKill` | `special_infected_kills` | +6 | `kills_all_specials` | ✅ Active |
| 4 | `PType_TankKill` | `tank_kills` | Variable | `tanks_killed` | ✅ Active |
| 5 | `PType_WitchKill` | `witch_kills` | +15 | `kills_witch` | ✅ Active |
| 6 | `PType_TankKill_Solo` | `tank_solo_kills` | +20 | `tanks_killed_solo` | ✅ Active |
| 7 | `PType_TankKill_Melee` | `tank_melee_kills` | +50 | `tanks_killed_melee` | ✅ Active |
| 8 | `PType_Headshot` | `common_headshots` | +2 | `common_headshots` | ✅ Active |
| 9 | `PType_FriendlyFire` | `friendly_fire_damage` | -30 | `survivor_ff` | ✅ Active |
| 10 | `PType_HealOther` | `heal_teammate` | +40-60 | `heal_others` | ✅ Active |
| 11 | `PType_ReviveOther` | `revive_teammate` | +25 | `revived_others` | ✅ Active |
| 12 | `PType_ResurrectOther` | `defib_teammate` | +50 | `defibs_used` | ✅ Active |
| 13 | `PType_DeployAmmo` | `ammo_pack_deploy` | +20 | `packs_used` | ✅ Active |
| 14 | `PType_WitchCrown` | `witch_crowns` | +25 | `witches_crowned` | ✅ Active |
| 15 | `PType_MeleeKill` | `melee_kills` | +1 | `melee_kills` | ✅ Active |
| 16 | `PType_PillUse` | `pills_use` | +10 | `pills_used` | ✅ Active |
| 17 | `PType_AdrenalineUse` | `adrenaline_use` | +15 | `adrenaline_used` | ✅ Active |
| 18 | `PType_MolotovUse` | `molotov_use` | +5 | `pickups_molotov` | ✅ Active |
| 19 | `PType_PipeUse` | `pipe_use` | +5 | `pickups_pipe_bomb` | ✅ Active |
| 20 | `PType_BileUse` | `bile_use` | +5 | `pickups_vomitjar` | ✅ Active |
| 21 | `PType_TankDamage` | `tank_damage` | Variable | `damage_to_tank` | 🔄 Planned |
| 22 | `PType_ClearPinned` | `clear_pinned` | +15 | `cleared_pinned` | ✅ Active |
| 23 | `PType_SmokerSelfClear` | `smoker_self_clear` | +10 | `smokers_selfcleared` | ✅ Active |
| 24 | `PType_HunterDeadstop` | `hunter_deadstop` | +20 | `hunters_deadstopped` | ✅ Active |
| 25 | `PType_BoomerBileHit` | `boomer_bile_hits` | +3 | `boomer_mellos` | ✅ Active |
| 26 | `PType_Death` | `death_penalty` | -10 | `survivor_deaths` | ✅ Active |
| 27 | `PType_CarAlarm` | `car_alarm_penalty` | -10 | `caralarms_activated` | ✅ Active |
| 28 | `PType_TimesPinned` | `times_pinned_penalty` | -5 | `times_pinned` | ✅ Active |
| 29 | `PType_TankRockHit` | `tank_rocks_hit` | -10 | `rocks_hitby` | ✅ Active |
| 30 | `PType_ClownHonk` | `clown_honks` | -5 | `clowns_honked` | ✅ Active |
| 31 | `PType_BoomerBileSelf` | `boomer_bile_self` | -5 | `boomer_mellos_self` | ✅ Active |
| 32 | `PType_TeammateKill` | `teammate_kill_penalty` | -500 | `ff_kills` | ✅ Active |

## Point System Rules Detail

### Base Points (Positive Actions)

```json
{
  "base_points": {
    "rules": {
      "common_kills": { "points_per_kill": 1, "source_field": "common_kills" },
      "common_headshots": { "points_per_headshot": 2, "source_field": "common_headshots" },
      "special_infected_kills": { "points_per_kill": 6, "source_field": "kills_all_specials" },
      "witch_kills": { "points_per_kill": 15, "source_field": "kills_witch" },
      "witch_crowns": { "points_per_crown": 25, "source_field": "witches_crowned" },
      "tank_kills": { "points_per_kill": 50, "source_field": "tanks_killed" },
      "tank_solo_kills": { "points_per_kill": 20, "source_field": "tanks_killed_solo" },
      "tank_melee_kills": { "points_per_kill": 50, "source_field": "tanks_killed_melee" },
      "heal_teammate": { "points_per_heal": 40, "source_field": "heal_others" },
      "revive_teammate": { "points_per_revive": 25, "source_field": "revived_others" },
      "defib_teammate": { "points_per_defib": 50, "source_field": "defibs_used" },
      "ammo_pack_deploy": { "points_per_pack": 20, "source_field": "packs_used" },
      "melee_kills": { "points_per_kill": 1, "source_field": "melee_kills" },
      "pills_use": { "points_per_use": 10, "source_field": "pills_used" },
      "adrenaline_use": { "points_per_use": 15, "source_field": "adrenaline_used" },
      "molotov_use": { "points_per_use": 5, "source_field": "pickups_molotov" },
      "pipe_use": { "points_per_use": 5, "source_field": "pickups_pipe_bomb" },
      "bile_use": { "points_per_use": 5, "source_field": "pickups_vomitjar" },
      "clear_pinned": { "points_per_clear": 15, "source_field": "cleared_pinned" },
      "smoker_self_clear": { "points_per_clear": 10, "source_field": "smokers_selfcleared" },
      "hunter_deadstop": { "points_per_deadstop": 20, "source_field": "hunters_deadstopped" },
      "boomer_bile_hits": { "points_per_hit": 3, "source_field": "boomer_mellos" },
      "finale_win": { "points_per_win": 1000, "source_field": "finales_won" }
    }
  }
}
```

### Penalty Points (Negative Actions)

```json
{
  "penalties": {
    "rules": {
      "friendly_fire_damage": { "points_per_damage": -30, "source_field": "survivor_ff" },
      "teammate_kill_penalty": { "points_per_kill": -500, "source_field": "ff_kills" },
      "death_penalty": { "points_per_death": -10, "source_field": "survivor_deaths" },
      "car_alarm_penalty": { "points_per_alarm": -10, "source_field": "caralarms_activated" },
      "times_pinned_penalty": { "points_per_pin": -5, "source_field": "times_pinned" },
      "tank_rocks_hit": { "points_per_hit": -10, "source_field": "rocks_hitby" },
      "clown_honks": { "points_per_honk": -5, "source_field": "clowns_honked" },
      "boomer_bile_self": { "points_per_bile": -5, "source_field": "boomer_mellos_self" }
    }
  }
}
```

## Implementation Status

### ✅ Fully Implemented (31/33)
- All base point types working correctly
- All penalty types working correctly
- Individual transaction recording active
- Database fields properly updated

### 🔄 Planned Implementation (2/33)
- **Type 21 (PType_TankDamage)**: Individual tank damage points
- **Type 25 (PType_BoomerBileHit)**: Boomer bile hits on enemies

## Validation Checklist

### For Each Point Type:
- [ ] SourcePawn enum defined
- [ ] RecordPoint() call implemented
- [ ] IncrementStat() call added
- [ ] IncrementMapStat() call added (if applicable)
- [ ] Database field exists
- [ ] Point-system.json rule defined
- [ ] Frontend display added
- [ ] Documentation updated

## Maintenance Notes

1. **Adding New Point Types**:
   - Add to PointRecordType enum (next available number)
   - Add RecordPoint() call in appropriate event handler
   - Add IncrementStat() and IncrementMapStat() calls
   - Update point-system.json with new rule
   - Add to frontend display
   - Update this mapping document

2. **Modifying Point Values**:
   - Update point-system.json configuration
   - RecordPoint() calls use fixed values - may need plugin update
   - Test with /recalculate API to verify changes

3. **Database Schema Changes**:
   - Add new fields to all 3 tables: stats_users, stats_map_users, stats_games
   - Update main stats update query in plugin
   - Update map stats logic if needed

## Related Files

- **Plugin**: `scripting/l4d2_stats_recorder.sp`
- **Config**: `website-api/config/point-system.json`
- **Frontend**: `website-ui/src/components/user/points.vue`
- **Database**: `data/init.sql`
- **Documentation**: `docs/database/STATS_POINTS_TYPE_REFERENCE.md`
