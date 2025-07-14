-- Fix friendly fire received data aggregation
-- This script recalculates survivor_ff_rec from stats_games.SurvivorFFTakenDamage

USE left4dead2;

-- Show current status before fix
SELECT 'Before Fix - Users with NULL survivor_ff_rec:' as status;
SELECT COUNT(*) as null_count FROM stats_users WHERE survivor_ff_rec IS NULL;

SELECT 'Before Fix - Sample data:' as status;
SELECT steamid, last_alias, survivor_ff, survivor_ff_rec 
FROM stats_users 
ORDER BY points DESC 
LIMIT 5;

-- Recalculate survivor_ff_rec for all users
UPDATE stats_users 
SET survivor_ff_rec = (
    SELECT COALESCE(SUM(SurvivorFFTakenDamage), 0) 
    FROM stats_games 
    WHERE stats_games.steamid = stats_users.steamid
);

-- Show status after fix
SELECT 'After Fix - Users with NULL survivor_ff_rec:' as status;
SELECT COUNT(*) as null_count FROM stats_users WHERE survivor_ff_rec IS NULL;

SELECT 'After Fix - Sample data:' as status;
SELECT steamid, last_alias, survivor_ff, survivor_ff_rec 
FROM stats_users 
ORDER BY points DESC 
LIMIT 5;

-- Verify data consistency
SELECT 'Verification - Games data vs aggregated data:' as status;
SELECT 
    u.steamid,
    u.last_alias,
    u.survivor_ff_rec as aggregated_ff_received,
    COALESCE(SUM(g.SurvivorFFTakenDamage), 0) as calculated_ff_received
FROM stats_users u
LEFT JOIN stats_games g ON u.steamid = g.steamid
GROUP BY u.steamid, u.last_alias, u.survivor_ff_rec
HAVING u.survivor_ff_rec != COALESCE(SUM(g.SurvivorFFTakenDamage), 0)
LIMIT 10;