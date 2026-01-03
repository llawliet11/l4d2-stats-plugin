-- Cleanup penalty columns after moving to API-based point calculation
-- This removes the survivor_ff_penalty columns that are no longer needed
-- since penalty calculation is now handled entirely by the API

USE left4dead2;

-- Step 1: Create backup of current data
DROP TABLE IF EXISTS stats_users_penalty_cleanup_backup;
CREATE TABLE stats_users_penalty_cleanup_backup AS 
SELECT steamid, last_alias, survivor_ff, survivor_ff_penalty, survivor_ff_rec, points 
FROM stats_users 
WHERE survivor_ff_penalty > 0;

DROP TABLE IF EXISTS stats_map_users_penalty_cleanup_backup;
CREATE TABLE stats_map_users_penalty_cleanup_backup AS 
SELECT steamid, mapid, survivor_ff, survivor_ff_penalty, survivor_ff_rec 
FROM stats_map_users 
WHERE survivor_ff_penalty > 0;

SELECT 'Backup tables created successfully' as status;

-- Step 2: Show current data before cleanup
SELECT 'BEFORE CLEANUP - stats_users with penalty data:' as status;
SELECT COUNT(*) as users_with_penalty_data FROM stats_users WHERE survivor_ff_penalty > 0;

SELECT 'BEFORE CLEANUP - stats_map_users with penalty data:' as status;
SELECT COUNT(*) as map_sessions_with_penalty_data FROM stats_map_users WHERE survivor_ff_penalty > 0;

-- Step 3: Verify survivor_ff contains actual damage (should be reasonable values)
SELECT 'Current survivor_ff values (should be actual damage):' as status;
SELECT 
    steamid,
    last_alias,
    survivor_ff as actual_damage,
    survivor_ff_penalty as old_penalty_points,
    survivor_ff_rec as damage_received
FROM stats_users 
WHERE survivor_ff > 0 
ORDER BY survivor_ff DESC 
LIMIT 10;

-- Step 4: Remove survivor_ff_penalty column from stats_users
SELECT 'Removing survivor_ff_penalty column from stats_users...' as status;
ALTER TABLE stats_users DROP COLUMN survivor_ff_penalty;

-- Step 5: Remove survivor_ff_penalty column from stats_map_users
SELECT 'Removing survivor_ff_penalty column from stats_map_users...' as status;
ALTER TABLE stats_map_users DROP COLUMN survivor_ff_penalty;

-- Step 6: Verify cleanup
SELECT 'AFTER CLEANUP - stats_users structure:' as status;
SHOW COLUMNS FROM stats_users LIKE '%survivor_ff%';

SELECT 'AFTER CLEANUP - stats_map_users structure:' as status;
SHOW COLUMNS FROM stats_map_users LIKE '%survivor_ff%';

-- Step 7: Final verification - show current FF data
SELECT 'FINAL STATE - Friendly fire data in stats_users:' as status;
SELECT 
    steamid,
    last_alias,
    survivor_ff as ff_damage_dealt,
    survivor_ff_rec as ff_damage_received
FROM stats_users 
WHERE survivor_ff > 0 OR survivor_ff_rec > 0
ORDER BY survivor_ff DESC 
LIMIT 10;

SELECT 'Cleanup completed successfully!' as status;
SELECT 'Point calculation is now handled entirely by API using point-system.json' as note;
SELECT 'survivor_ff now contains actual damage values for display' as note2;
SELECT 'Penalty calculation is done dynamically using configurable rules' as note3;
