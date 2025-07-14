-- Fix for friendly fire received data
-- This script recalculates survivor_ff_rec in stats_users table 
-- from the SurvivorFFTakenDamage field in stats_games table

-- Step 1: Create a backup table for safety
CREATE TABLE IF NOT EXISTS stats_users_ff_backup AS 
SELECT steamid, survivor_ff_rec 
FROM stats_users 
WHERE survivor_ff_rec > 0 OR EXISTS (
    SELECT 1 FROM stats_games 
    WHERE stats_games.steamid = stats_users.steamid 
    AND SurvivorFFTakenDamage > 0
);

-- Step 2: Show current state before fix
SELECT 
    'Before Fix' as status,
    COUNT(*) as total_users,
    COUNT(CASE WHEN survivor_ff_rec > 0 THEN 1 END) as users_with_ff_rec,
    SUM(survivor_ff_rec) as total_ff_rec_damage,
    AVG(survivor_ff_rec) as avg_ff_rec_damage
FROM stats_users;

-- Step 3: Recalculate survivor_ff_rec from stats_games data
UPDATE stats_users u
SET survivor_ff_rec = (
    SELECT COALESCE(SUM(g.SurvivorFFTakenDamage), 0)
    FROM stats_games g 
    WHERE g.steamid = u.steamid 
    AND g.SurvivorFFTakenDamage IS NOT NULL
);

-- Step 4: Show state after fix
SELECT 
    'After Fix' as status,
    COUNT(*) as total_users,
    COUNT(CASE WHEN survivor_ff_rec > 0 THEN 1 END) as users_with_ff_rec,
    SUM(survivor_ff_rec) as total_ff_rec_damage,
    AVG(survivor_ff_rec) as avg_ff_rec_damage
FROM stats_users;

-- Step 5: Show sample users with both friendly fire dealt and received
SELECT 
    steamid,
    last_alias,
    survivor_ff as ff_dealt,
    survivor_ff_rec as ff_received,
    CASE 
        WHEN survivor_ff > 0 AND survivor_ff_rec > 0 THEN 'Both'
        WHEN survivor_ff > 0 THEN 'Only Dealt'
        WHEN survivor_ff_rec > 0 THEN 'Only Received'
        ELSE 'None'
    END as ff_status
FROM stats_users 
WHERE survivor_ff > 0 OR survivor_ff_rec > 0
ORDER BY (survivor_ff + survivor_ff_rec) DESC
LIMIT 10;

-- Step 6: Verify data consistency by comparing with raw stats_games data
SELECT 
    'Data Consistency Check' as check_type,
    u.steamid,
    u.last_alias,
    u.survivor_ff_rec as calculated_ff_rec,
    g.actual_ff_rec,
    CASE 
        WHEN u.survivor_ff_rec = g.actual_ff_rec THEN 'MATCH'
        ELSE 'MISMATCH'
    END as status
FROM stats_users u
LEFT JOIN (
    SELECT 
        steamid, 
        SUM(COALESCE(SurvivorFFTakenDamage, 0)) as actual_ff_rec
    FROM stats_games 
    WHERE SurvivorFFTakenDamage IS NOT NULL
    GROUP BY steamid
) g ON u.steamid = g.steamid
WHERE (u.survivor_ff_rec > 0 OR g.actual_ff_rec > 0)
AND (u.survivor_ff_rec != g.actual_ff_rec OR (u.survivor_ff_rec IS NULL AND g.actual_ff_rec IS NOT NULL))
LIMIT 5;