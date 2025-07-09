-- Drop all existing tables
DROP TABLE IF EXISTS `stats_weapons_usage`;
DROP TABLE IF EXISTS `stats_heatmaps`;
DROP TABLE IF EXISTS `stats_points`;
DROP TABLE IF EXISTS `stats_games`;
DROP TABLE IF EXISTS `stats_users`;
DROP TABLE IF EXISTS `map_info`;

-- Now load the original schema
SOURCE stats_database.sql;