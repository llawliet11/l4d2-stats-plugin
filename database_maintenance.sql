-- L4D2 Stats Database Maintenance and Diagnostic Queries
-- This file contains useful queries for maintaining and diagnosing the L4D2 stats database

-- 1. DIAGNOSTIC QUERIES

-- Check for users with playtime discrepancies (recorded vs calculated)
SELECT 
    u.steamid,
    u.last_alias,
    u.minutes_played as recorded_minutes,
    COALESCE(SUM(CASE 
        WHEN g.date_end > 0 AND g.date_start > 0 
        THEN (g.date_end - g.date_start) / 60 
        ELSE 0 
    END), 0) as calculated_minutes,
    ABS(u.minutes_played - COALESCE(SUM(CASE 
        WHEN g.date_end > 0 AND g.date_start > 0 
        THEN (g.date_end - g.date_start) / 60 
        ELSE 0 
    END), 0)) as difference,
    COUNT(g.id) as session_count
FROM stats_users u
LEFT JOIN stats_games g ON u.steamid = g.steamid
GROUP BY u.steamid, u.last_alias, u.minutes_played
HAVING ABS(difference) > 10 AND session_count > 0
ORDER BY difference DESC;

-- Check for users with zero points but significant activity
SELECT 
    u.steamid,
    u.last_alias,
    u.points,
    u.minutes_played,
    u.common_kills,
    u.kills_all_specials,
    u.revived_others,
    u.heal_others,
    COUNT(g.id) as sessions
FROM stats_users u
LEFT JOIN stats_games g ON u.steamid = g.steamid
WHERE u.points = 0 AND (u.minutes_played > 30 OR u.common_kills > 0 OR u.kills_all_specials > 0)
GROUP BY u.steamid
ORDER BY u.minutes_played DESC;

-- Check for invalid session data
SELECT 
    id,
    steamid,
    campaignID,
    date_start,
    date_end,
    (date_end - date_start) as duration_seconds,
    (date_end - date_start) / 60 as duration_minutes
FROM stats_games 
WHERE date_start <= 0 OR date_end <= 0 OR date_end < date_start OR (date_end - date_start) > 86400
ORDER BY id DESC
LIMIT 20;

-- 2. MAINTENANCE QUERIES

-- Update playtime for users with discrepancies (DRY RUN - use SELECT first)
-- SELECT 
--     u.steamid,
--     u.last_alias,
--     u.minutes_played as old_minutes,
--     COALESCE(SUM(CASE 
--         WHEN g.date_end > 0 AND g.date_start > 0 
--         THEN (g.date_end - g.date_start) / 60 
--         ELSE 0 
--     END), 0) as new_minutes
-- FROM stats_users u
-- LEFT JOIN stats_games g ON u.steamid = g.steamid
-- GROUP BY u.steamid
-- HAVING ABS(u.minutes_played - new_minutes) > 10;

-- Actual update query (UNCOMMENT TO USE):
-- UPDATE stats_users u
-- SET minutes_played = (
--     SELECT COALESCE(SUM(CASE 
--         WHEN g.date_end > 0 AND g.date_start > 0 
--         THEN (g.date_end - g.date_start) / 60 
--         ELSE 0 
--     END), u.minutes_played)
--     FROM stats_games g 
--     WHERE g.steamid = u.steamid
-- )
-- WHERE EXISTS (
--     SELECT 1 FROM stats_games g 
--     WHERE g.steamid = u.steamid 
--     AND g.date_end > 0 AND g.date_start > 0
-- );

-- 3. PERFORMANCE QUERIES

-- Find users with most sessions
SELECT 
    u.steamid,
    u.last_alias,
    COUNT(g.id) as total_sessions,
    SUM(CASE WHEN g.date_end > 0 AND g.date_start > 0 THEN (g.date_end - g.date_start) / 60 ELSE 0 END) as total_minutes
FROM stats_users u
JOIN stats_games g ON u.steamid = g.steamid
GROUP BY u.steamid, u.last_alias
ORDER BY total_sessions DESC
LIMIT 10;

-- Find most popular maps
SELECT 
    map,
    COUNT(*) as session_count,
    AVG(CASE WHEN date_end > 0 AND date_start > 0 THEN (date_end - date_start) / 60 ELSE NULL END) as avg_duration_minutes
FROM stats_games 
WHERE map IS NOT NULL AND map != ''
GROUP BY map
ORDER BY session_count DESC
LIMIT 15;

-- 4. DATA QUALITY CHECKS

-- Check for duplicate sessions (same user, same campaign, overlapping times)
SELECT 
    g1.steamid,
    g1.campaignID,
    g1.date_start as start1,
    g1.date_end as end1,
    g2.date_start as start2,
    g2.date_end as end2
FROM stats_games g1
JOIN stats_games g2 ON g1.steamid = g2.steamid 
    AND g1.campaignID = g2.campaignID 
    AND g1.id < g2.id
WHERE (g1.date_start BETWEEN g2.date_start AND g2.date_end)
   OR (g1.date_end BETWEEN g2.date_start AND g2.date_end)
   OR (g2.date_start BETWEEN g1.date_start AND g1.date_end)
   OR (g2.date_end BETWEEN g1.date_start AND g1.date_end)
LIMIT 10;

-- Check for users with unrealistic stats
SELECT 
    steamid,
    last_alias,
    points,
    minutes_played,
    common_kills,
    kills_all_specials,
    CASE WHEN minutes_played > 0 THEN common_kills / minutes_played ELSE 0 END as kills_per_minute
FROM stats_users
WHERE minutes_played > 0 
    AND (common_kills / GREATEST(minutes_played, 1) > 50 OR points / GREATEST(minutes_played, 1) > 100)
ORDER BY kills_per_minute DESC
LIMIT 10;
