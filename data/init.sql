/*M!999999\- enable the sandbox mode */
-- MariaDB dump 10.19-11.7.2-MariaDB, for debian-linux-gnu (aarch64)
--
-- Host: localhost    Database: left4dead2
-- ------------------------------------------------------
-- Server version	11.7.2-MariaDB-ubu2404

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
-- Table structure for table `stats_map_users`
--

DROP TABLE IF EXISTS `stats_map_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `stats_map_users` (
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
                                   `mapid` varchar(32) NOT NULL,
                                   `session_start` bigint(20) unsigned NOT NULL,
                                   `session_end` bigint(20) unsigned DEFAULT NULL,
                                   PRIMARY KEY (`steamid`,`mapid`,`session_start`),
                                   KEY `points` (`steamid`),
                                   KEY `idx_map_users_mapid` (`mapid`),
                                   KEY `idx_map_users_steamid` (`steamid`),
                                   KEY `idx_map_users_session` (`session_start`,`session_end`),
                                   FULLTEXT KEY `last_alias` (`last_alias`),
                                   CONSTRAINT `fk_map_users_mapid` FOREIGN KEY (`mapid`) REFERENCES `map_info` (`mapid`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

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
                                `mapId` varchar(32) DEFAULT NULL,
                                PRIMARY KEY (`id`),
                                KEY `stats_points_stats_users_steamid_fk` (`steamid`),
                                KEY `stats_points_timestamp_index` (`timestamp`),
                                KEY `idx_stats_points_mapId` (`mapId`)
) ENGINE=InnoDB AUTO_INCREMENT=2710 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

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
                               `points` int(10) unsigned NOT NULL DEFAULT 0,
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
                               PRIMARY KEY (`steamid`),
                               KEY `points` (`steamid`),
                               FULLTEXT KEY `last_alias` (`last_alias`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

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
                                      `points` int(10) unsigned NOT NULL DEFAULT 0,
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
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*M!100616 SET NOTE_VERBOSITY=@OLD_NOTE_VERBOSITY */;

-- Dump completed on 2025-07-17 18:39:55
