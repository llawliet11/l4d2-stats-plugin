# Stats Users Table Column Analysis

## Complete Column List from Database Schema

Based on `data/init.sql`, the `stats_users` table has the following columns:

### Core Identity Columns
1. `steamid` (varchar(20)) - Primary Key
2. `last_alias` (varchar(32)) - Player name
3. `last_join_date` (bigint(11)) - Last connection timestamp
4. `created_date` (bigint(11)) - First join timestamp
5. `connections` (int(11)) - Number of connections
6. `country` (varchar(45)) - Player country

### Game Statistics Columns (Numeric)
7. `points` (int(10)) - Player points
8. `survivor_deaths` (int(11)) - Deaths as survivor
9. `infected_deaths` (int(11)) - Deaths as infected
10. `survivor_damage_rec` (bigint(11)) - Damage received as survivor
11. `survivor_damage_give` (bigint(11)) - Damage given as survivor
12. `infected_damage_rec` (bigint(11)) - Damage received as infected
13. `infected_damage_give` (bigint(11)) - Damage given as infected
14. `pickups_molotov` (int(11)) - Molotov pickups
15. `pickups_pipe_bomb` (int(11)) - Pipe bomb pickups
16. `survivor_incaps` (int(11)) - Incapacitations
17. `pills_used` (int(11)) - Pills used
18. `defibs_used` (int(11)) - Defibrillators used
19. `adrenaline_used` (int(11)) - Adrenaline used
20. `heal_self` (int(11)) - Self heals
21. `heal_others` (int(11)) - Heals on others
22. `revived` (int(11)) - Times revived by others
23. `revived_others` (int(11)) - Times revived others
24. `pickups_pain_pills` (int(11)) - Pain pills pickups
25. `melee_kills` (int(11)) - Melee kills
26. `tanks_killed` (int(10)) - Tanks killed
27. `tanks_killed_solo` (int(10)) - Tanks killed solo
28. `tanks_killed_melee` (int(10)) - Tanks killed with melee
29. `survivor_ff` (int(10)) - Friendly fire damage given
30. `survivor_ff_rec` (int(11)) - Friendly fire damage received
31. `common_kills` (int(10)) - Common infected kills
32. `common_headshots` (int(10)) - Common infected headshots
33. `door_opens` (int(10)) - Doors opened
34. `damage_to_tank` (int(10)) - Damage dealt to tank
35. `damage_as_tank` (int(10)) - Damage dealt as tank
36. `damage_witch` (int(10)) - Damage dealt to witch
37. `minutes_played` (int(10)) - Minutes played
38. `finales_won` (int(10)) - Finales completed
39. `kills_smoker` (int(10)) - Smoker kills
40. `kills_boomer` (int(10)) - Boomer kills
41. `kills_hunter` (int(10)) - Hunter kills
42. `kills_spitter` (int(10)) - Spitter kills
43. `kills_jockey` (int(10)) - Jockey kills
44. `kills_charger` (int(10)) - Charger kills
45. `kills_witch` (int(10)) - Witch kills
46. `packs_used` (int(10)) - Upgrade packs used
47. `ff_kills` (int(10)) - Friendly fire kills
48. `throws_puke` (int(10)) - Bile bomb throws
49. `throws_molotov` (int(10)) - Molotov throws
50. `throws_pipe` (int(10)) - Pipe bomb throws
51. `damage_molotov` (int(10)) - Damage from molotov
52. `kills_molotov` (int(10)) - Kills from molotov
53. `kills_pipe` (int(10)) - Kills from pipe bomb
54. `kills_minigun` (int(10)) - Kills from minigun
55. `caralarms_activated` (smallint(5)) - Car alarms activated
56. `witches_crowned` (int(10)) - Witches crowned
57. `witches_crowned_angry` (smallint(5)) - Angry witches crowned
58. `smokers_selfcleared` (int(10)) - Smokers self-cleared
59. `rocks_hitby` (int(10)) - Tank rocks hit by
60. `hunters_deadstopped` (int(10)) - Hunters deadstopped
61. `cleared_pinned` (int(10)) - Times cleared pinned survivors
62. `times_pinned` (int(10)) - Times pinned by special infected
63. `clowns_honked` (smallint(5)) - Clowns honked
64. `minutes_idle` (mediumint(8)) - Minutes idle
65. `boomer_mellos` (int(11)) - Boomer mellos (custom stat)
66. `boomer_mellos_self` (smallint(6)) - Self boomer mellos
67. `forgot_kit_count` (smallint(5)) - Forgot kit count
68. `total_distance_travelled` (float) - Total distance travelled

## Columns Likely to Have All Zeros

Based on the plugin analysis and common L4D2 gameplay patterns, these columns are likely to have all values = 0:

### **Highly Likely All Zeros (Not Implemented in Plugin):**
1. `pickups_molotov` - No pickup tracking in plugin
2. `pickups_pipe_bomb` - No pickup tracking in plugin  
3. `pickups_pain_pills` - No pickup tracking in plugin
4. `throws_puke` - No bile bomb throw tracking
5. `throws_molotov` - No molotov throw tracking
6. `throws_pipe` - No pipe bomb throw tracking
7. `damage_as_tank` - Versus mode not tracked
8. `infected_deaths` - Versus mode not tracked
9. `infected_damage_rec` - Versus mode not tracked
10. `infected_damage_give` - Versus mode not tracked
11. `witches_crowned_angry` - Specific witch state not tracked
12. `cleared_pinned` - Advanced skill not tracked in plugin
13. `boomer_mellos` - Custom stat, unclear implementation
14. `boomer_mellos_self` - Custom stat, unclear implementation
15. `forgot_kit_count` - Custom stat, unclear implementation

### **Possibly All Zeros (Rare Events):**
1. `tanks_killed_solo` - Requires solo tank kill
2. `tanks_killed_melee` - Requires melee-only tank kill
3. `ff_kills` - Friendly fire kills (rare)
4. `kills_minigun` - Minigun kills (map-specific)

### **Should Have Data (Implemented in Plugin):**
- All special infected kills (`kills_smoker`, `kills_boomer`, etc.)
- `survivor_deaths`, `survivor_incaps`
- `common_kills`, `melee_kills`
- `survivor_ff`, `survivor_ff_rec`
- `minutes_played`, `points`
- `heal_others`, `revived_others`
- `door_opens`, `damage_to_tank`

## Recommendation

Run the SQL analysis script to identify which columns actually have all zeros in your database. Columns with all zeros can potentially be:
1. **Removed** if they're truly unused
2. **Kept** if they're planned for future features
3. **Investigated** if they should have data but don't (plugin bugs)

## Total Column Count: 68 columns
