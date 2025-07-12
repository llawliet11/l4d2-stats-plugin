-- Script to remove foreign key constraints from left4dead2 database
-- This allows points to be inserted without requiring users to exist first

USE left4dead2;

-- Remove foreign key constraint from stats_points table
ALTER TABLE `stats_points` DROP FOREIGN KEY `stats_points_stats_users_steamid_fk`;

-- Remove foreign key constraint from stats_games table  
ALTER TABLE `stats_games` DROP FOREIGN KEY `matchUser`;

-- Verify constraints have been removed
SELECT 
    TABLE_NAME,
    CONSTRAINT_NAME,
    CONSTRAINT_TYPE,
    REFERENCED_TABLE_NAME
FROM information_schema.TABLE_CONSTRAINTS 
WHERE TABLE_SCHEMA = 'left4dead2' 
AND CONSTRAINT_TYPE = 'FOREIGN KEY';