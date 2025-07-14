/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19-11.8.2-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: left4dead2
-- ------------------------------------------------------
-- Server version	11.8.2-MariaDB-ubu2404

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*M!100616 SET @OLD_NOTE_VERBOSITY=@@NOTE_VERBOSITY, NOTE_VERBOSITY=0 */;

--
-- Table structure for table `map_info`
--

DROP TABLE IF EXISTS `map_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `map_info` (
  `mission_id` varchar(64) DEFAULT NULL,
  `mapid` varchar(32) NOT NULL,
  `name` varchar(128) NOT NULL,
  `chapter_count` smallint(6) DEFAULT NULL,
  `flags` smallint(6) DEFAULT 0 COMMENT '1:official',
  PRIMARY KEY (`mapid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `map_info`
--

LOCK TABLES `map_info` WRITE;
/*!40000 ALTER TABLE `map_info` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `map_info` VALUES
(NULL,'dune_05','Vox Aeterna',5,0),
(NULL,'requiem_05','Prodeus Requiem',5,0),
(NULL,'td_shinjuku','Tokyo Dark',3,0);
/*!40000 ALTER TABLE `map_info` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `map_ratings`
--

DROP TABLE IF EXISTS `map_ratings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `map_ratings` (
  `map_id` varchar(64) NOT NULL,
  `steamid` varchar(32) NOT NULL,
  `value` tinyint(4) NOT NULL,
  `comment` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`map_id`,`steamid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `map_ratings`
--

LOCK TABLES `map_ratings` WRITE;
/*!40000 ALTER TABLE `map_ratings` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `map_ratings` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `stats_games`
--

DROP TABLE IF EXISTS `stats_games`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `stats_games` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `steamid` varchar(20) NOT NULL,
  `map` varchar(128) NOT NULL COMMENT 'the map id',
  `flags` tinyint(4) NOT NULL DEFAULT 0,
  `campaignID` uuid NOT NULL COMMENT 'unique campaign session id',
  `gamemode` varchar(30) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `difficulty` tinyint(2) NOT NULL DEFAULT 0,
  `duration` int(11) GENERATED ALWAYS AS ((`date_end` - `date_start`) / 60) VIRTUAL COMMENT 'in minutes',
  `join_time` bigint(20) unsigned NOT NULL COMMENT 'when user first joined game',
  `date_start` bigint(20) unsigned DEFAULT NULL COMMENT 'when campaign started',
  `date_end` bigint(20) NOT NULL,
  `finale_time` int(11) unsigned NOT NULL,
  `characterType` tinyint(3) unsigned DEFAULT NULL,
  `ping` tinyint(4) unsigned DEFAULT NULL,
  `server_tags` text DEFAULT NULL,
  `ZombieKills` int(10) unsigned NOT NULL DEFAULT 0,
  `MeleeKills` smallint(10) unsigned NOT NULL DEFAULT 0,
  `SurvivorDamage` int(10) unsigned NOT NULL DEFAULT 0,
  `SurvivorFFCount` mediumint(8) unsigned NOT NULL DEFAULT 0,
  `SurvivorFFTakenCount` int(11) DEFAULT NULL,
  `SurvivorFFDamage` int(11) DEFAULT NULL,
  `SurvivorFFTakenDamage` int(11) DEFAULT NULL,
  `MedkitsUsed` tinyint(10) unsigned NOT NULL DEFAULT 0,
  `FirstAidShared` tinyint(10) unsigned NOT NULL DEFAULT 0,
  `PillsUsed` smallint(10) unsigned NOT NULL DEFAULT 0,
  `MolotovsUsed` smallint(10) unsigned NOT NULL DEFAULT 0,
  `PipebombsUsed` smallint(10) unsigned NOT NULL DEFAULT 0,
  `BoomerBilesUsed` smallint(10) unsigned NOT NULL DEFAULT 0,
  `AdrenalinesUsed` smallint(10) unsigned NOT NULL DEFAULT 0,
  `DefibrillatorsUsed` smallint(10) unsigned NOT NULL DEFAULT 0,
  `DamageTaken` int(10) unsigned NOT NULL DEFAULT 0,
  `ReviveOtherCount` smallint(10) unsigned NOT NULL DEFAULT 0,
  `Incaps` smallint(10) unsigned NOT NULL DEFAULT 0,
  `Deaths` tinyint(10) unsigned NOT NULL DEFAULT 0,
  `boomer_kills` smallint(10) unsigned DEFAULT NULL,
  `smoker_kills` smallint(10) unsigned DEFAULT NULL,
  `jockey_kills` smallint(10) unsigned DEFAULT NULL,
  `hunter_kills` smallint(10) unsigned DEFAULT NULL,
  `spitter_kills` smallint(10) unsigned DEFAULT NULL,
  `charger_kills` smallint(10) unsigned DEFAULT NULL,
  `SpecialInfectedKills` int(10) unsigned GENERATED ALWAYS AS (`boomer_kills` + `spitter_kills` + `jockey_kills` + `charger_kills` + `hunter_kills` + `smoker_kills`) VIRTUAL,
  `honks` smallint(5) unsigned DEFAULT 0,
  `top_weapon` varchar(64) DEFAULT NULL,
  `minutes_idle` mediumint(8) unsigned NOT NULL DEFAULT 0,
  `WitchesCrowned` mediumint(8) unsigned NOT NULL DEFAULT 0,
  `SmokersSelfCleared` mediumint(8) unsigned NOT NULL DEFAULT 0,
  `RocksHitBy` mediumint(8) unsigned NOT NULL DEFAULT 0,
  `RocksDodged` mediumint(8) unsigned NOT NULL DEFAULT 0,
  `HuntersDeadstopped` mediumint(8) unsigned NOT NULL DEFAULT 0,
  `TimesPinned` mediumint(8) unsigned NOT NULL DEFAULT 0,
  `ClearedPinned` mediumint(8) unsigned DEFAULT 0,
  `BoomedTeammates` smallint(5) unsigned NOT NULL DEFAULT 0,
  `TimesBoomed` mediumint(8) unsigned NOT NULL DEFAULT 0,
  `DamageToTank` mediumint(8) unsigned NOT NULL DEFAULT 0,
  `DamageToWitch` mediumint(8) unsigned NOT NULL DEFAULT 0,
  `DamageDealt` int(10) unsigned NOT NULL DEFAULT 0,
  `CarAlarmsActivated` tinyint(3) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `userindex` (`steamid`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stats_games`
--

LOCK TABLES `stats_games` WRITE;
/*!40000 ALTER TABLE `stats_games` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `stats_games` VALUES
(1,'STEAM_1:0:727844272','requiem_05',0,'509bd8e6-5f15-11f0-976f-02420a0b0013','coop',2,9,1752312985,1752320533,1752321058,499,4,1,'',307,55,313,72,104,189,384,3,0,2,2,0,0,0,0,395,2,4,0,58,31,0,57,0,0,146,3,'weapon_shotgun_spas',0,0,0,0,0,0,0,0,0,0,0,0,0,0),
(2,'STEAM_1:1:50902447','requiem_05',0,'509bd8e6-5f15-11f0-976f-02420a0b0013','coop',2,9,1752313168,1752320533,1752321058,499,0,5,'',349,77,734,123,41,407,144,6,1,1,1,1,0,1,0,336,4,1,0,50,61,0,84,0,0,195,7,'weapon_rifle_desert',0,0,0,0,0,0,0,0,0,0,0,0,0,0),
(3,'STEAM_1:1:42077851','requiem_05',0,'509bd8e6-5f15-11f0-976f-02420a0b0013','coop',2,9,1752313024,1752320533,1752321058,499,5,5,'',269,1,585,82,116,392,393,3,0,1,1,4,1,1,0,552,1,4,1,31,44,0,21,0,0,96,5,'crowbar',0,0,0,0,0,0,0,0,0,0,0,0,0,0),
(4,'STEAM_1:0:77194684','requiem_05',0,'509bd8e6-5f15-11f0-976f-02420a0b0013','coop',2,9,1752313028,1752320533,1752321058,499,6,5,'',320,0,441,78,91,252,307,2,1,1,1,2,0,1,0,329,4,3,1,74,56,0,61,0,0,191,12,'weapon_autoshotgun',0,0,0,0,0,0,0,0,0,0,0,0,0,0);
/*!40000 ALTER TABLE `stats_games` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `stats_heatmaps`
--

DROP TABLE IF EXISTS `stats_heatmaps`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `stats_heatmaps` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `steamid` varchar(32) NOT NULL,
  `timestamp` int(11) NOT NULL DEFAULT unix_timestamp(),
  `map` varchar(64) NOT NULL,
  `type` smallint(6) NOT NULL,
  `x` int(11) DEFAULT NULL,
  `y` int(11) DEFAULT NULL,
  `z` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=409357 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stats_heatmaps`
--

LOCK TABLES `stats_heatmaps` WRITE;
/*!40000 ALTER TABLE `stats_heatmaps` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `stats_heatmaps` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `stats_points`
--

DROP TABLE IF EXISTS `stats_points`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `stats_points` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `steamid` varchar(32) NOT NULL,
  `type` smallint(6) NOT NULL,
  `amount` smallint(6) NOT NULL,
  `timestamp` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `stats_points_stats_users_steamid_fk` (`steamid`),
  KEY `stats_points_timestamp_index` (`timestamp`)
) ENGINE=InnoDB AUTO_INCREMENT=2847 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stats_points`
--

LOCK TABLES `stats_points` WRITE;
/*!40000 ALTER TABLE `stats_points` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `stats_points` VALUES
(2823,'STEAM_1:0:727844272',0,2037,1752321058),
(2824,'STEAM_1:1:50902447',0,1771,1752321058),
(2825,'STEAM_1:1:42077851',0,980,1752321058),
(2826,'STEAM_1:0:77194684',0,2294,1752321058),
(2827,'STEAM_1:1:28498421',9,-120,1752505431),
(2828,'STEAM_1:1:28498421',9,-120,1752505431),
(2829,'STEAM_1:1:28498421',8,2,1752505445),
(2830,'STEAM_1:1:28498421',2,1,1752505445),
(2831,'STEAM_1:1:28498421',8,2,1752505445),
(2832,'STEAM_1:1:28498421',2,1,1752505445),
(2833,'STEAM_1:1:28498421',2,1,1752505445),
(2834,'STEAM_1:1:28498421',2,1,1752505448),
(2835,'STEAM_1:1:28498421',2,1,1752505449),
(2836,'STEAM_1:1:28498421',2,1,1752505451),
(2837,'STEAM_1:1:28498421',2,1,1752505453),
(2838,'STEAM_1:1:28498421',2,1,1752505456),
(2839,'STEAM_1:1:28498421',2,1,1752505456),
(2840,'STEAM_1:1:28498421',2,1,1752505457),
(2841,'STEAM_1:1:28498421',2,1,1752505461),
(2842,'STEAM_1:1:28498421',2,1,1752505462),
(2843,'STEAM_1:1:28498421',3,6,1752505466),
(2844,'STEAM_1:1:28498421',2,1,1752505466),
(2845,'STEAM_1:1:28498421',2,1,1752505470),
(2846,'STEAM_1:1:28498421',3,6,1752505491);
/*!40000 ALTER TABLE `stats_points` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `stats_users`
--

DROP TABLE IF EXISTS `stats_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `stats_users` (
  `steamid` varchar(20) NOT NULL,
  `last_alias` varchar(32) NOT NULL,
  `last_join_date` bigint(11) NOT NULL,
  `created_date` bigint(11) NOT NULL,
  `connections` int(11) unsigned NOT NULL DEFAULT 1,
  `country` varchar(45) NOT NULL,
  `points` int(10) NOT NULL DEFAULT 0,
  `survivor_deaths` int(11) unsigned NOT NULL DEFAULT 0,
  `infected_deaths` int(11) unsigned NOT NULL DEFAULT 0,
  `survivor_damage_rec` bigint(11) unsigned NOT NULL DEFAULT 0,
  `survivor_damage_give` bigint(11) unsigned NOT NULL DEFAULT 0,
  `infected_damage_rec` bigint(11) unsigned NOT NULL DEFAULT 0,
  `infected_damage_give` bigint(11) unsigned NOT NULL DEFAULT 0,
  `pickups_molotov` int(11) unsigned NOT NULL DEFAULT 0,
  `pickups_pipe_bomb` int(11) unsigned NOT NULL DEFAULT 0,
  `survivor_incaps` int(11) unsigned NOT NULL DEFAULT 0,
  `pills_used` int(11) unsigned NOT NULL DEFAULT 0,
  `defibs_used` int(11) unsigned NOT NULL DEFAULT 0,
  `adrenaline_used` int(11) unsigned NOT NULL DEFAULT 0,
  `heal_self` int(11) unsigned NOT NULL DEFAULT 0,
  `heal_others` int(11) unsigned NOT NULL DEFAULT 0,
  `revived` int(11) unsigned NOT NULL DEFAULT 0 COMMENT 'Times themselves revived',
  `revived_others` int(11) unsigned NOT NULL DEFAULT 0,
  `pickups_pain_pills` int(11) unsigned NOT NULL DEFAULT 0,
  `melee_kills` int(11) unsigned DEFAULT 0,
  `tanks_killed` int(10) unsigned NOT NULL DEFAULT 0,
  `tanks_killed_solo` int(10) unsigned NOT NULL DEFAULT 0,
  `tanks_killed_melee` int(10) unsigned NOT NULL DEFAULT 0,
  `survivor_ff` int(10) unsigned NOT NULL DEFAULT 0,
  `survivor_ff_rec` int(11) DEFAULT 0,
  `common_kills` int(10) unsigned DEFAULT 0,
  `common_headshots` int(10) unsigned NOT NULL DEFAULT 0,
  `door_opens` int(10) unsigned NOT NULL DEFAULT 0,
  `damage_to_tank` int(10) unsigned DEFAULT 0,
  `damage_as_tank` int(10) unsigned NOT NULL DEFAULT 0,
  `damage_witch` int(10) unsigned NOT NULL DEFAULT 0,
  `minutes_played` int(10) unsigned NOT NULL DEFAULT 0,
  `finales_won` int(10) unsigned NOT NULL DEFAULT 0,
  `kills_smoker` int(10) unsigned NOT NULL DEFAULT 0,
  `kills_boomer` int(10) unsigned NOT NULL DEFAULT 0,
  `kills_hunter` int(10) unsigned NOT NULL DEFAULT 0,
  `kills_spitter` int(10) unsigned NOT NULL DEFAULT 0,
  `kills_jockey` int(10) unsigned NOT NULL DEFAULT 0,
  `kills_charger` int(10) unsigned NOT NULL DEFAULT 0,
  `kills_witch` int(10) unsigned NOT NULL DEFAULT 0,
  `packs_used` int(10) unsigned NOT NULL DEFAULT 0,
  `ff_kills` int(10) unsigned NOT NULL DEFAULT 0,
  `throws_puke` int(10) unsigned NOT NULL DEFAULT 0,
  `throws_molotov` int(10) unsigned NOT NULL DEFAULT 0,
  `throws_pipe` int(10) unsigned NOT NULL DEFAULT 0,
  `damage_molotov` int(10) unsigned NOT NULL DEFAULT 0,
  `kills_molotov` int(10) unsigned NOT NULL DEFAULT 0,
  `kills_pipe` int(10) unsigned NOT NULL DEFAULT 0,
  `kills_minigun` int(10) unsigned NOT NULL DEFAULT 0,
  `kills_all_specials` int(10) unsigned NOT NULL DEFAULT 0,
  `caralarms_activated` smallint(5) unsigned NOT NULL DEFAULT 0,
  `witches_crowned` int(10) unsigned NOT NULL DEFAULT 0,
  `witches_crowned_angry` smallint(5) unsigned NOT NULL DEFAULT 0,
  `smokers_selfcleared` int(10) unsigned NOT NULL DEFAULT 0,
  `rocks_hitby` int(10) unsigned NOT NULL DEFAULT 0,
  `hunters_deadstopped` int(10) unsigned NOT NULL DEFAULT 0,
  `cleared_pinned` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'Times cleared a survivor thats pinned',
  `times_pinned` int(10) unsigned NOT NULL DEFAULT 0,
  `clowns_honked` smallint(5) unsigned NOT NULL DEFAULT 0,
  `minutes_idle` mediumint(8) unsigned NOT NULL DEFAULT 0,
  `boomer_mellos` int(11) DEFAULT 0,
  `boomer_mellos_self` smallint(6) DEFAULT 0,
  `forgot_kit_count` smallint(5) unsigned NOT NULL DEFAULT 0,
  `total_distance_travelled` float DEFAULT 0,
  `mvp_wins` int(11) DEFAULT 0,
  `ff_damage_received` int(11) DEFAULT 0,
  PRIMARY KEY (`steamid`),
  KEY `points` (`steamid`),
  FULLTEXT KEY `last_alias` (`last_alias`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stats_users`
--

LOCK TABLES `stats_users` WRITE;
/*!40000 ALTER TABLE `stats_users` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `stats_users` VALUES
('STEAM_1:0:727844272','Nusty',1752317937,1752293844,8,'',2037,41,0,6119,593245,0,0,0,0,112,16,0,5,36,2,73,37,0,492,35,0,0,6899,384,3429,0,61,53713,0,6321,429,1,132,219,185,0,0,0,9,1,1,3,8,4,1719,109,13,0,0,8,0,0,3,0,62,285,237,88,0,41,12,2,40121900000,0,0),
('STEAM_1:0:77194684','wang',1752317939,1752293884,8,'',2294,35,0,7675,646345,0,0,0,0,99,23,3,10,26,40,58,58,0,153,36,0,0,9945,307,4819,0,104,51070,0,9424,422,1,188,277,217,0,0,0,11,4,1,8,7,29,631,103,4,0,0,9,0,0,3,3,53,233,216,109,0,43,22,5,52282000000,0,0),
('STEAM_1:1:28498421','Nusty_Testing',1752509467,1752421262,11,'',-1743,2,0,397,2806,0,0,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0,105,0,22,0,4,0,0,0,24,0,1,6,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,3,0,0,0,0,0,14073700000,0,0),
('STEAM_1:1:42077851','GOD',1752317937,1752293863,8,'',980,35,0,7854,360825,0,0,0,0,97,11,0,5,33,16,47,29,0,276,34,0,0,8874,393,3749,0,43,37293,0,2975,421,1,131,125,91,0,0,0,2,6,0,13,13,123,679,2105,1,0,0,2,0,0,1,2,28,128,197,148,0,14,5,1,53419600000,0,0),
('STEAM_1:1:50902447','Anlv',1752317937,1752293881,8,'',1771,33,0,7132,626891,0,0,0,0,73,7,3,5,16,52,31,85,0,1799,34,0,0,15693,144,4652,0,11,76520,0,5996,417,1,240,188,266,0,0,0,9,10,1,1,29,22,3537,171,18,0,0,6,0,0,3,4,35,217,215,108,0,30,14,2,47457700000,0,0);
/*!40000 ALTER TABLE `stats_users` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `stats_users_backup`
--

DROP TABLE IF EXISTS `stats_users_backup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `stats_users_backup` (
  `steamid` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `last_alias` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `last_join_date` bigint(11) NOT NULL,
  `created_date` bigint(11) NOT NULL,
  `connections` int(11) unsigned NOT NULL DEFAULT 1,
  `country` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `points` int(10) NOT NULL DEFAULT 0,
  `survivor_deaths` int(11) unsigned NOT NULL DEFAULT 0,
  `infected_deaths` int(11) unsigned NOT NULL DEFAULT 0,
  `survivor_damage_rec` bigint(11) unsigned NOT NULL DEFAULT 0,
  `survivor_damage_give` bigint(11) unsigned NOT NULL DEFAULT 0,
  `infected_damage_rec` bigint(11) unsigned NOT NULL DEFAULT 0,
  `infected_damage_give` bigint(11) unsigned NOT NULL DEFAULT 0,
  `pickups_molotov` int(11) unsigned NOT NULL DEFAULT 0,
  `pickups_pipe_bomb` int(11) unsigned NOT NULL DEFAULT 0,
  `survivor_incaps` int(11) unsigned NOT NULL DEFAULT 0,
  `pills_used` int(11) unsigned NOT NULL DEFAULT 0,
  `defibs_used` int(11) unsigned NOT NULL DEFAULT 0,
  `adrenaline_used` int(11) unsigned NOT NULL DEFAULT 0,
  `heal_self` int(11) unsigned NOT NULL DEFAULT 0,
  `heal_others` int(11) unsigned NOT NULL DEFAULT 0,
  `revived` int(11) unsigned NOT NULL DEFAULT 0 COMMENT 'Times themselves revived',
  `revived_others` int(11) unsigned NOT NULL DEFAULT 0,
  `pickups_pain_pills` int(11) unsigned NOT NULL DEFAULT 0,
  `melee_kills` int(11) unsigned DEFAULT 0,
  `tanks_killed` int(10) unsigned NOT NULL DEFAULT 0,
  `tanks_killed_solo` int(10) unsigned NOT NULL DEFAULT 0,
  `tanks_killed_melee` int(10) unsigned NOT NULL DEFAULT 0,
  `survivor_ff` int(10) unsigned NOT NULL DEFAULT 0,
  `survivor_ff_rec` int(11) DEFAULT 0,
  `common_kills` int(10) unsigned DEFAULT 0,
  `common_headshots` int(10) unsigned NOT NULL DEFAULT 0,
  `door_opens` int(10) unsigned NOT NULL DEFAULT 0,
  `damage_to_tank` int(10) unsigned DEFAULT 0,
  `damage_as_tank` int(10) unsigned NOT NULL DEFAULT 0,
  `damage_witch` int(10) unsigned NOT NULL DEFAULT 0,
  `minutes_played` int(10) unsigned NOT NULL DEFAULT 0,
  `finales_won` int(10) unsigned NOT NULL DEFAULT 0,
  `kills_smoker` int(10) unsigned NOT NULL DEFAULT 0,
  `kills_boomer` int(10) unsigned NOT NULL DEFAULT 0,
  `kills_hunter` int(10) unsigned NOT NULL DEFAULT 0,
  `kills_spitter` int(10) unsigned NOT NULL DEFAULT 0,
  `kills_jockey` int(10) unsigned NOT NULL DEFAULT 0,
  `kills_charger` int(10) unsigned NOT NULL DEFAULT 0,
  `kills_witch` int(10) unsigned NOT NULL DEFAULT 0,
  `packs_used` int(10) unsigned NOT NULL DEFAULT 0,
  `ff_kills` int(10) unsigned NOT NULL DEFAULT 0,
  `throws_puke` int(10) unsigned NOT NULL DEFAULT 0,
  `throws_molotov` int(10) unsigned NOT NULL DEFAULT 0,
  `throws_pipe` int(10) unsigned NOT NULL DEFAULT 0,
  `damage_molotov` int(10) unsigned NOT NULL DEFAULT 0,
  `kills_molotov` int(10) unsigned NOT NULL DEFAULT 0,
  `kills_pipe` int(10) unsigned NOT NULL DEFAULT 0,
  `kills_minigun` int(10) unsigned NOT NULL DEFAULT 0,
  `kills_all_specials` int(10) unsigned NOT NULL DEFAULT 0,
  `caralarms_activated` smallint(5) unsigned NOT NULL DEFAULT 0,
  `witches_crowned` int(10) unsigned NOT NULL DEFAULT 0,
  `witches_crowned_angry` smallint(5) unsigned NOT NULL DEFAULT 0,
  `smokers_selfcleared` int(10) unsigned NOT NULL DEFAULT 0,
  `rocks_hitby` int(10) unsigned NOT NULL DEFAULT 0,
  `hunters_deadstopped` int(10) unsigned NOT NULL DEFAULT 0,
  `cleared_pinned` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'Times cleared a survivor thats pinned',
  `times_pinned` int(10) unsigned NOT NULL DEFAULT 0,
  `clowns_honked` smallint(5) unsigned NOT NULL DEFAULT 0,
  `minutes_idle` mediumint(8) unsigned NOT NULL DEFAULT 0,
  `boomer_mellos` int(11) DEFAULT 0,
  `boomer_mellos_self` smallint(6) DEFAULT 0,
  `forgot_kit_count` smallint(5) unsigned NOT NULL DEFAULT 0,
  `total_distance_travelled` float DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stats_users_backup`
--

LOCK TABLES `stats_users_backup` WRITE;
/*!40000 ALTER TABLE `stats_users_backup` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `stats_users_backup` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `stats_weapons_usage`
--

DROP TABLE IF EXISTS `stats_weapons_usage`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `stats_weapons_usage` (
  `steamid` varchar(32) NOT NULL,
  `weapon` varchar(64) NOT NULL,
  `minutesUsed` float DEFAULT NULL,
  `totalDamage` bigint(20) NOT NULL,
  `headshots` int(11) DEFAULT NULL,
  `kills` int(11) DEFAULT NULL,
  PRIMARY KEY (`steamid`,`weapon`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stats_weapons_usage`
--

LOCK TABLES `stats_weapons_usage` WRITE;
/*!40000 ALTER TABLE `stats_weapons_usage` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `stats_weapons_usage` VALUES
('STEAM_1:0:727844272','baseball_bat',603,20390,10,189),
('STEAM_1:0:727844272','fireaxe',547,19839,12,150),
('STEAM_1:0:727844272','frying_pan',9,101,0,2),
('STEAM_1:0:727844272','katana',223,6550,6,81),
('STEAM_1:0:727844272','keycard',3,0,0,0),
('STEAM_1:0:727844272','knife',737,37407,21,222),
('STEAM_1:0:727844272','kopis',375,8127,5,80),
('STEAM_1:0:727844272','machete',836,15393,18,186),
('STEAM_1:0:727844272','shovel',257,14425,9,68),
('STEAM_1:0:727844272','spear',282,4775,4,60),
('STEAM_1:0:727844272','tonfa',233,7347,6,90),
('STEAM_1:0:727844272','weapon_autoshotgun',335,9664,10,143),
('STEAM_1:0:727844272','weapon_chainsaw',2,0,0,0),
('STEAM_1:0:727844272','weapon_pistol',4791,93585,76,930),
('STEAM_1:0:727844272','weapon_pistol_magnum',87,1447,0,14),
('STEAM_1:0:727844272','weapon_pumpshotgun',3173,51069,29,621),
('STEAM_1:0:727844272','weapon_rifle',300,5882,14,65),
('STEAM_1:0:727844272','weapon_rifle_ak47',1656,47671,45,482),
('STEAM_1:0:727844272','weapon_rifle_desert',567,15754,20,197),
('STEAM_1:0:727844272','weapon_rifle_sg552',1,0,0,0),
('STEAM_1:0:727844272','weapon_shotgun_chrome',3062,54959,35,667),
('STEAM_1:0:727844272','weapon_shotgun_spas',2403,41834,47,558),
('STEAM_1:0:727844272','weapon_smg',139,1541,2,23),
('STEAM_1:0:727844272','weapon_smg_mp5',23,555,0,1),
('STEAM_1:0:727844272','weapon_smg_silenced',1,0,0,0),
('STEAM_1:0:727844272','weapon_sniper_awp',158,3886,1,18),
('STEAM_1:0:727844272','weapon_sniper_military',539,19969,23,204),
('STEAM_1:0:727844272','weapon_sniper_scout',15,1876,2,21),
('STEAM_1:0:77194684','baseball_bat',211,8144,15,80),
('STEAM_1:0:77194684','crowbar',373,13799,6,73),
('STEAM_1:0:77194684','katana',94,1810,1,20),
('STEAM_1:0:77194684','keycard',9,0,0,0),
('STEAM_1:0:77194684','knife',3,0,0,0),
('STEAM_1:0:77194684','kopis',130,8012,2,9),
('STEAM_1:0:77194684','machete',1808,49414,37,418),
('STEAM_1:0:77194684','shovel',311,6457,7,39),
('STEAM_1:0:77194684','spear',175,7274,2,54),
('STEAM_1:0:77194684','tonfa',194,4986,6,42),
('STEAM_1:0:77194684','weapon_autoshotgun',2163,47989,42,506),
('STEAM_1:0:77194684','weapon_chainsaw',16,101,0,2),
('STEAM_1:0:77194684','weapon_pistol',5571,123274,148,1213),
('STEAM_1:0:77194684','weapon_pistol_magnum',222,5303,1,51),
('STEAM_1:0:77194684','weapon_pumpshotgun',4980,106597,89,1102),
('STEAM_1:0:77194684','weapon_rifle',310,10280,21,88),
('STEAM_1:0:77194684','weapon_rifle_ak47',2829,98016,178,848),
('STEAM_1:0:77194684','weapon_rifle_desert',634,15385,42,191),
('STEAM_1:0:77194684','weapon_rifle_sg552',14,1082,4,14),
('STEAM_1:0:77194684','weapon_shotgun_chrome',1252,32443,21,345),
('STEAM_1:0:77194684','weapon_shotgun_spas',10,0,0,0),
('STEAM_1:0:77194684','weapon_smg',171,469,1,18),
('STEAM_1:0:77194684','weapon_smg_mp5',200,4316,16,60),
('STEAM_1:0:77194684','weapon_sniper_military',511,17645,20,182),
('STEAM_1:0:77194684','weapon_sniper_scout',4,0,0,0),
('STEAM_1:1:28498421','machete',3,0,0,0),
('STEAM_1:1:28498421','weapon_pistol',31,190,0,3),
('STEAM_1:1:28498421','weapon_shotgun_chrome',56,1218,2,13),
('STEAM_1:1:28498421','weapon_sniper_military',47,340,1,1),
('STEAM_1:1:42077851','cricket_bat',3,0,0,0),
('STEAM_1:1:42077851','crowbar',324,8880,11,69),
('STEAM_1:1:42077851','frying_pan',63,903,0,10),
('STEAM_1:1:42077851','katana',166,767,1,11),
('STEAM_1:1:42077851','keycard',6,0,0,0),
('STEAM_1:1:42077851','knife',380,3737,3,41),
('STEAM_1:1:42077851','kopis',199,4326,18,85),
('STEAM_1:1:42077851','machete',1160,29520,37,230),
('STEAM_1:1:42077851','shovel',11,0,0,0),
('STEAM_1:1:42077851','spear',124,2407,3,42),
('STEAM_1:1:42077851','tonfa',32,952,0,20),
('STEAM_1:1:42077851','weapon_autoshotgun',888,14447,33,202),
('STEAM_1:1:42077851','weapon_pistol',4507,39319,57,538),
('STEAM_1:1:42077851','weapon_pistol_magnum',532,4258,7,64),
('STEAM_1:1:42077851','weapon_pumpshotgun',49,0,0,0),
('STEAM_1:1:42077851','weapon_rifle',3141,55753,82,823),
('STEAM_1:1:42077851','weapon_rifle_ak47',1086,20172,21,298),
('STEAM_1:1:42077851','weapon_rifle_desert',520,10166,10,129),
('STEAM_1:1:42077851','weapon_rifle_m60',17,1179,1,17),
('STEAM_1:1:42077851','weapon_rifle_sg552',345,5065,8,57),
('STEAM_1:1:42077851','weapon_shotgun_chrome',104,1761,2,17),
('STEAM_1:1:42077851','weapon_shotgun_spas',947,14482,9,151),
('STEAM_1:1:42077851','weapon_smg',2712,30706,72,433),
('STEAM_1:1:42077851','weapon_smg_mp5',5046,66593,130,1009),
('STEAM_1:1:42077851','weapon_smg_silenced',121,1438,3,30),
('STEAM_1:1:42077851','weapon_sniper_awp',6,0,0,0),
('STEAM_1:1:42077851','weapon_sniper_military',267,8427,4,69),
('STEAM_1:1:42077851','weapon_sniper_scout',287,2938,2,23),
('STEAM_1:1:50902447','baseball_bat',476,11040,13,105),
('STEAM_1:1:50902447','cricket_bat',63,7953,6,45),
('STEAM_1:1:50902447','frying_pan',200,7158,2,65),
('STEAM_1:1:50902447','keycard',22,0,0,0),
('STEAM_1:1:50902447','knife',63,828,5,14),
('STEAM_1:1:50902447','kopis',1049,34733,21,286),
('STEAM_1:1:50902447','machete',75,1454,2,31),
('STEAM_1:1:50902447','shovel',202,9720,6,56),
('STEAM_1:1:50902447','spear',4767,138444,91,1512),
('STEAM_1:1:50902447','tonfa',201,8800,5,100),
('STEAM_1:1:50902447','weapon_autoshotgun',561,18195,20,213),
('STEAM_1:1:50902447','weapon_chainsaw',2,0,0,0),
('STEAM_1:1:50902447','weapon_pistol',1994,43677,43,317),
('STEAM_1:1:50902447','weapon_pistol_magnum',40,981,0,5),
('STEAM_1:1:50902447','weapon_pumpshotgun',161,1888,0,29),
('STEAM_1:1:50902447','weapon_rifle',2315,50192,82,564),
('STEAM_1:1:50902447','weapon_rifle_ak47',756,21746,29,207),
('STEAM_1:1:50902447','weapon_rifle_desert',2301,70460,74,593),
('STEAM_1:1:50902447','weapon_rifle_sg552',247,6548,9,51),
('STEAM_1:1:50902447','weapon_shotgun_chrome',113,0,0,0),
('STEAM_1:1:50902447','weapon_shotgun_spas',193,4999,2,56),
('STEAM_1:1:50902447','weapon_smg',4451,71227,134,634),
('STEAM_1:1:50902447','weapon_smg_mp5',1726,36190,52,285),
('STEAM_1:1:50902447','weapon_smg_silenced',294,3378,5,35),
('STEAM_1:1:50902447','weapon_sniper_awp',540,20177,2,105),
('STEAM_1:1:50902447','weapon_sniper_military',472,23582,11,142),
('STEAM_1:1:50902447','weapon_sniper_scout',996,10804,5,38);
/*!40000 ALTER TABLE `stats_weapons_usage` ENABLE KEYS */;
UNLOCK TABLES;
commit;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*M!100616 SET NOTE_VERBOSITY=@OLD_NOTE_VERBOSITY */;

-- Dump completed on 2025-07-14 16:45:15
