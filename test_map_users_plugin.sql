-- Test script to validate stats_map_users functionality
-- This simulates what the plugin would do

USE left4dead2;

-- Test 1: Insert a new map session (simulating player connect)
INSERT INTO stats_map_users (
    steamid, mapid, session_start, 
    common_kills, survivor_deaths, session_end
) VALUES (
    'STEAM_1:0:999999999', 'requiem_05', UNIX_TIMESTAMP(),
    0, 0, NULL
) ON DUPLICATE KEY UPDATE session_end = UNIX_TIMESTAMP();

-- Test 2: Update stats during gameplay (simulating IncrementMapStat)
INSERT INTO stats_map_users (
    steamid, mapid, session_start, 
    common_kills, session_end
) VALUES (
    'STEAM_1:0:999999999', 'requiem_05', UNIX_TIMESTAMP() - 300,
    5, UNIX_TIMESTAMP()
) ON DUPLICATE KEY UPDATE 
    common_kills = common_kills + 5, 
    session_end = UNIX_TIMESTAMP();

-- Test 3: Verify the data
SELECT 
    steamid, mapid, common_kills, 
    FROM_UNIXTIME(session_start) as start_time,
    FROM_UNIXTIME(session_end) as end_time
FROM stats_map_users 
WHERE steamid = 'STEAM_1:0:999999999';

-- Test 4: Verify foreign key relationship
SELECT 
    smu.mapid, smu.common_kills,
    mi.name as map_name, mi.chapter_count
FROM stats_map_users smu
JOIN map_info mi ON smu.mapid = mi.mapid
WHERE smu.steamid = 'STEAM_1:0:999999999';

-- Cleanup test data
DELETE FROM stats_map_users WHERE steamid = 'STEAM_1:0:999999999';