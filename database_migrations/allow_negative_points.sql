-- Allow negative points in stats_users table
-- Change points column from unsigned to signed integer

USE left4dead2;

-- Modify the points column to allow negative values
ALTER TABLE stats_users MODIFY COLUMN points int(10) NOT NULL DEFAULT 0;

-- Also modify the backup table if it exists
ALTER TABLE stats_users_backup MODIFY COLUMN points int(10) NOT NULL DEFAULT 0;

-- Verify the changes
DESCRIBE stats_users;