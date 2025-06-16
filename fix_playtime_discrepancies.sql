-- Fix playtime discrepancies in the L4D2 stats database
-- This script corrects users whose recorded minutes_played doesn't match their actual session time

-- First, let's create a temporary table to calculate correct playtime for all users
CREATE TEMPORARY TABLE temp_correct_playtime AS
SELECT 
    u.steamid,
    u.last_alias,
    u.minutes_played as current_minutes,
    COALESCE(SUM(CASE 
        WHEN g.date_end > 0 AND g.date_start > 0 
        THEN (g.date_end - g.date_start) / 60 
        ELSE 0 
    END), 0) as calculated_minutes,
    COUNT(g.id) as session_count
FROM stats_users u
LEFT JOIN stats_games g ON u.steamid = g.steamid
GROUP BY u.steamid, u.last_alias, u.minutes_played;

-- Show users with significant discrepancies (more than 10 minutes difference)
SELECT 
    steamid,
    last_alias,
    current_minutes,
    calculated_minutes,
    (calculated_minutes - current_minutes) as difference,
    session_count
FROM temp_correct_playtime 
WHERE ABS(calculated_minutes - current_minutes) > 10
ORDER BY ABS(calculated_minutes - current_minutes) DESC;

-- Update users with significant playtime discrepancies
-- Only update if calculated time is greater than current time (to avoid reducing legitimate playtime)
UPDATE stats_users u
JOIN temp_correct_playtime t ON u.steamid = t.steamid
SET u.minutes_played = GREATEST(u.minutes_played, ROUND(t.calculated_minutes))
WHERE t.calculated_minutes > u.minutes_played + 10;

-- Show the results after the update
SELECT 
    'After Update' as status,
    COUNT(*) as users_updated
FROM stats_users u
JOIN temp_correct_playtime t ON u.steamid = t.steamid
WHERE t.calculated_minutes > u.minutes_played + 10;

-- Clean up
DROP TEMPORARY TABLE temp_correct_playtime;
