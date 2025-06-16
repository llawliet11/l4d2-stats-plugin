-- Comprehensive fix for L4D2 stats database issues
-- This script addresses both playtime discrepancies and points calculation problems

-- Step 1: Create a backup of current user stats
CREATE TABLE IF NOT EXISTS stats_users_backup AS SELECT * FROM stats_users;

-- Step 2: Fix playtime discrepancies for all users
-- Calculate correct playtime based on actual session data
UPDATE stats_users u
SET minutes_played = (
    SELECT COALESCE(SUM(CASE 
        WHEN g.date_end > 0 AND g.date_start > 0 
        THEN (g.date_end - g.date_start) / 60 
        ELSE 0 
    END), u.minutes_played)
    FROM stats_games g 
    WHERE g.steamid = u.steamid
)
WHERE EXISTS (
    SELECT 1 FROM stats_games g 
    WHERE g.steamid = u.steamid 
    AND g.date_end > 0 AND g.date_start > 0
);

-- Step 3: Recalculate points using an improved formula that accounts for playtime
-- This formula is more balanced and considers the actual time played
UPDATE stats_users 
SET points = GREATEST(0, (
    -- Base scoring (scaled appropriately)
    (common_kills * 0.001) +                    -- 0.001 points per common kill
    (kills_all_specials * 0.5) +               -- 0.5 points per special kill
    (revived_others * 2.0) +                   -- 2 points per revive
    (heal_others * 1.0) +                      -- 1 point per heal
    (cleared_pinned * 1.5) +                   -- 1.5 points per rescue
    (witches_crowned * 5.0) +                  -- 5 points per witch crown
    ((kills_molotov + kills_pipe) * 0.5) +     -- 0.5 points per throwable kill
    
    -- Penalties (negative points)
    (survivor_incaps * -1.0) +                 -- -1 point per incap
    (survivor_deaths * -2.0) +                 -- -2 points per death
    (survivor_ff * -0.001) +                   -- -0.001 points per FF damage
    (rocks_hitby * -1.0) +                     -- -1 point per tank rock hit
    
    -- Time-based bonuses (encourage longer play sessions)
    (CASE 
        WHEN minutes_played > 0 THEN 
            (damage_to_tank * 0.01 / GREATEST(minutes_played, 1)) * minutes_played +  -- Tank damage bonus
            (minutes_played * 0.1)                                                     -- Time bonus
        ELSE 0 
    END)
))
WHERE minutes_played > 0;

-- Step 4: Show the results of our fixes
SELECT 
    'Fixed Users Summary' as report_type,
    COUNT(*) as total_users,
    AVG(minutes_played) as avg_minutes,
    AVG(points) as avg_points,
    MIN(points) as min_points,
    MAX(points) as max_points
FROM stats_users 
WHERE minutes_played > 0;

-- Step 5: Show specific results for the users we were investigating
SELECT 
    steamid,
    last_alias,
    minutes_played,
    points,
    ROUND(points / GREATEST(minutes_played, 1), 2) as points_per_minute
FROM stats_users 
WHERE steamid IN ('STEAM_1:1:42077851', 'STEAM_1:0:171490983', 'STEAM_1:1:50902447', 'STEAM_1:0:727844272', 'STEAM_1:0:77194684')
ORDER BY points DESC;
