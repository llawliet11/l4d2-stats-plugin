-- Fix Orphaned Points Script
-- This script fixes issues where players have point records in stats_points
-- but their total points in stats_users is 0 or incorrect

-- 1. Find users with orphaned points (points in stats_points but 0 in stats_users)
SELECT 
    u.steamid,
    u.last_alias,
    u.points as current_points,
    COUNT(p.id) as point_records,
    COALESCE(SUM(p.amount), 0) as actual_points
FROM stats_users u
LEFT JOIN stats_points p ON u.steamid = p.steamid
WHERE u.points = 0
GROUP BY u.steamid, u.last_alias, u.points
HAVING COUNT(p.id) > 0;

-- 2. Fix the points for all users based on their point history
UPDATE stats_users u
SET points = (
    SELECT COALESCE(SUM(amount), 0)
    FROM stats_points p
    WHERE p.steamid = u.steamid
)
WHERE u.steamid IN (
    SELECT DISTINCT steamid 
    FROM stats_points
);

-- 3. Verify the fix - show users whose points were updated
SELECT 
    u.steamid,
    u.last_alias,
    u.points as updated_points,
    COUNT(p.id) as point_records
FROM stats_users u
LEFT JOIN stats_points p ON u.steamid = p.steamid
GROUP BY u.steamid, u.last_alias, u.points
HAVING u.points > 0
ORDER BY u.points DESC;

-- 4. Find any stats_points records without matching users (shouldn't happen with FK constraint)
SELECT 
    p.steamid,
    COUNT(*) as orphaned_records,
    SUM(p.amount) as total_points
FROM stats_points p
LEFT JOIN stats_users u ON p.steamid = u.steamid
WHERE u.steamid IS NULL
GROUP BY p.steamid;

-- 5. Clean up any duplicate or invalid Steam IDs
SELECT 
    steamid,
    COUNT(*) as count
FROM stats_users
WHERE steamid NOT LIKE 'STEAM_%:%:%'
   OR LENGTH(steamid) < 8
GROUP BY steamid;