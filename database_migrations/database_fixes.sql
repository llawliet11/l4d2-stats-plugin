-- Database Fixes for L4D2 Stats Plugin
-- Run this script to fix foreign key constraint and data integrity issues
-- Date: 2025-08-24

-- Fix 1: Add missing map_info record for l4d_fallen02_trenches
-- This resolves the foreign key constraint error
INSERT IGNORE INTO map_info (mapid, name, chapter_count, flags) 
VALUES ('l4d_fallen02_trenches', 'Fallen Trenches', 1, 0);

-- Fix 2: Add any other missing maps that have stats but no map_info record
-- Find orphaned maps in stats_map_users that don't exist in map_info
INSERT IGNORE INTO map_info (mapid, name, chapter_count, flags)
SELECT DISTINCT 
    smu.mapid as mapid,
    CONCAT('Map: ', smu.mapid) as name,
    1 as chapter_count,
    0 as flags
FROM stats_map_users smu
LEFT JOIN map_info mi ON smu.mapid = mi.mapid
WHERE mi.mapid IS NULL;

-- Fix 3: Add missing maps from stats_points table
INSERT IGNORE INTO map_info (mapid, name, chapter_count, flags)
SELECT DISTINCT 
    sp.mapId as mapid,
    CONCAT('Map: ', sp.mapId) as name,
    1 as chapter_count,
    0 as flags
FROM stats_points sp
LEFT JOIN map_info mi ON sp.mapId = mi.mapid
WHERE mi.mapid IS NULL AND sp.mapId IS NOT NULL AND sp.mapId != '';

-- Fix 4: Handle UNSIGNED INT points columns that can't store negative values
-- First, check if points columns are UNSIGNED and modify if needed
ALTER TABLE stats_users MODIFY COLUMN points int(10) NOT NULL DEFAULT 0;
ALTER TABLE stats_map_users MODIFY COLUMN points int(10) NOT NULL DEFAULT 0;

-- Fix 5: Clean up any corrupted points data that exceeds INT limits
-- Reset extreme values to reasonable limits (now supporting negative values)
UPDATE stats_users 
SET points = LEAST(2147483647, GREATEST(-2147483648, points))
WHERE points > 2147483647 OR points < -2147483648;

-- Fix 6: Clean up any corrupted map-specific points
UPDATE stats_map_users 
SET points = LEAST(2147483647, GREATEST(-2147483648, points))
WHERE points > 2147483647 OR points < -2147483648;

-- Fix 7: Remove any orphaned records with invalid Steam IDs
-- Clean up records that don't match proper Steam ID format
DELETE FROM stats_users 
WHERE steamid NOT LIKE 'STEAM_%:%:%' 
   OR LENGTH(steamid) < 8 
   OR LENGTH(steamid) > 32
   OR steamid LIKE '%PENDING%'
   OR steamid LIKE '%UNKNOWN%';

DELETE FROM stats_map_users 
WHERE steamid NOT LIKE 'STEAM_%:%:%' 
   OR LENGTH(steamid) < 8 
   OR LENGTH(steamid) > 32
   OR steamid LIKE '%PENDING%'
   OR steamid LIKE '%UNKNOWN%';

DELETE FROM stats_points 
WHERE steamid NOT LIKE 'STEAM_%:%:%' 
   OR LENGTH(steamid) < 8 
   OR LENGTH(steamid) > 32
   OR steamid LIKE '%PENDING%'
   OR steamid LIKE '%UNKNOWN%';

-- Fix 8: Verify all foreign key constraints are satisfied
-- Check for any remaining orphaned records
SELECT 'Orphaned stats_map_users records:' as check_type, COUNT(*) as count
FROM stats_map_users smu
LEFT JOIN map_info mi ON smu.mapid = mi.mapid
WHERE mi.mapid IS NULL
UNION ALL
SELECT 'Orphaned stats_points records:', COUNT(*)
FROM stats_points sp
LEFT JOIN map_info mi ON sp.mapId = mi.mapid
WHERE mi.mapid IS NULL AND sp.mapId IS NOT NULL AND sp.mapId != '';

-- Fix 9: Update any negative or zero chapter counts
UPDATE map_info SET chapter_count = 1 WHERE chapter_count IS NULL OR chapter_count <= 0;

-- Verification queries - run these to confirm fixes
SELECT 'Total maps in map_info:' as info, COUNT(*) as count FROM map_info
UNION ALL
SELECT 'Users with valid points:', COUNT(*) FROM stats_users WHERE points BETWEEN -2147483648 AND 2147483647
UNION ALL  
SELECT 'Map users with valid points:', COUNT(*) FROM stats_map_users WHERE points BETWEEN -2147483648 AND 2147483647;

-- Show the map that was causing issues
SELECT * FROM map_info WHERE mapid = 'l4d_fallen02_trenches';