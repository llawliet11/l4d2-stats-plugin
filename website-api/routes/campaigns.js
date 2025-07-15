import Router from 'express'
const router = Router()
import routeCache from 'route-cache'
import fs from 'fs'
import path from 'path'

// Load calculation rules from config file
const configPath = path.join(process.cwd(), 'config', 'calculation-rules.json')
let calculationRules = {}
try {
    calculationRules = JSON.parse(fs.readFileSync(configPath, 'utf8'))
} catch (err) {
    console.warn('Could not load calculation-rules.json, using defaults:', err.message)
    calculationRules = {
        mvp_calculation: {
            criteria: [
                { field: "SpecialInfectedKills", direction: "desc" },
                { field: "SurvivorFFCount", direction: "asc" },
                { field: "ZombieKills", direction: "desc" },
                { field: "DamageTaken", direction: "asc" },
                { field: "SurvivorDamage", direction: "asc" }
            ]
        },
        pagination: { campaigns_per_page: 4, max_per_page: 100 },
        cache_durations: { campaign_values: 600, campaign_details: 120, campaign_list: 60 },
        defaults: { server_tag_default: "prod", gamemode_search_all: "%" },
        map_classification: { official_map_pattern: "^c[0-9]+m" }
    }
}

export default function(pool) {
    router.get('/values', routeCache.cacheSeconds(calculationRules.cache_durations?.campaign_values || 600), async(req, res) => {
        const [gamemodes] = await pool.query("SELECT gamemode, COUNT(gamemode) count from stats_games GROUP BY gamemode ORDER BY count DESC")
        res.json({
            gamemodes
        })
    })
    router.get('/:id', routeCache.cacheSeconds(calculationRules.cache_durations?.campaign_details || 120), async(req,res) => {
        try {
            // Build MVP sorting criteria from config
            const mvpCriteria = calculationRules.mvp_calculation?.criteria || [
                { field: "SpecialInfectedKills", direction: "desc" },
                { field: "SurvivorFFCount", direction: "asc" },
                { field: "ZombieKills", direction: "desc" },
                { field: "DamageTaken", direction: "asc" },
                { field: "SurvivorDamage", direction: "asc" }
            ]
            const orderBy = mvpCriteria.map(c => `${c.field} ${c.direction}`).join(', ')
            
            let mapId = req.params.id
            let sessionStart = null
            let sessionEnd = null
            
            // Check if the ID looks like a campaign ID (8 chars or contains hyphens)
            // If so, resolve it to a map ID and get session timing via stats_games table
            if (req.params.id.length === 8 || req.params.id.includes('-')) {
                let campaignQuery
                let campaignParams
                
                if (req.params.id.length === 8) {
                    // Short campaign ID format (first 8 chars)
                    campaignQuery = `SELECT DISTINCT map, 
                                     MIN(date_start) as session_start, 
                                     MAX(date_end) as session_end 
                                     FROM stats_games 
                                     WHERE LEFT(campaignID, 8) = ? 
                                     GROUP BY map`
                    campaignParams = [req.params.id]
                } else {
                    // Full campaign UUID
                    campaignQuery = `SELECT DISTINCT map, 
                                     MIN(date_start) as session_start, 
                                     MAX(date_end) as session_end 
                                     FROM stats_games 
                                     WHERE campaignID = ? 
                                     GROUP BY map`
                    campaignParams = [req.params.id]
                }
                
                const [campaigns] = await pool.query(campaignQuery, campaignParams)
                if (campaigns.length > 0) {
                    mapId = campaigns[0].map
                    sessionStart = campaigns[0].session_start
                    sessionEnd = campaigns[0].session_end
                } else {
                    // No campaign found, return empty result
                    return res.json([])
                }
            }
            
            let query, params
            
            if (sessionStart && sessionEnd) {
                // Use stats_games for individual player session data
                query = `SELECT 
                    sg.steamid,
                    su.last_alias,
                    su.points,
                    mi.name as map_name,
                    sg.characterType,
                    FROM_UNIXTIME(sg.date_start) as date_played,
                    sg.date_start,
                    sg.date_end,
                    sg.campaignID,
                    sg.map,
                    sg.difficulty,
                    sg.gamemode,
                    -- Calculate fields for MVP compatibility using stats_games data
                    (COALESCE(sg.boomer_kills,0) + COALESCE(sg.smoker_kills,0) + 
                     COALESCE(sg.jockey_kills,0) + COALESCE(sg.hunter_kills,0) + 
                     COALESCE(sg.spitter_kills,0) + COALESCE(sg.charger_kills,0)) as SpecialInfectedKills,
                    sg.SurvivorFFCount,
                    sg.ZombieKills,
                    sg.DamageTaken,
                    sg.SurvivorDamage,
                    sg.Deaths,
                    sg.Incaps,
                    sg.MedkitsUsed,
                    sg.MeleeKills,
                    (sg.MolotovsUsed + sg.PipebombsUsed + sg.BoomerBilesUsed) as TotalThrowables,
                    (sg.PillsUsed + sg.AdrenalinesUsed) as TotalPillsShots,
                    -- Individual throwable/consumable data for MVP calculation
                    sg.MolotovsUsed as throws_molotov,
                    sg.PipebombsUsed as throws_pipe,
                    sg.BoomerBilesUsed as throws_puke,
                    sg.PillsUsed as pills_used,
                    sg.AdrenalinesUsed as adrenaline_used,
                    -- Additional MVP factors from stats_games (using available fields)
                    0 as tanks_killed,
                    0 as kills_witch,
                    0 as ff_kills,
                    sg.ReviveOtherCount as revived_others,
                    sg.DefibrillatorsUsed as defibs_used,
                    0 as finales_won
                FROM stats_games sg
                INNER JOIN stats_users su ON sg.steamid = su.steamid
                INNER JOIN map_info mi ON sg.map = mi.mapid
                WHERE sg.campaignID LIKE CONCAT(?, '%')
                ORDER BY ${orderBy}`
                params = [req.params.id.substring(0,8)]
            } else {
                // Fallback - use campaign/map ID directly with stats_games
                query = `SELECT 
                    sg.steamid,
                    su.last_alias,
                    su.points,
                    mi.name as map_name,
                    sg.characterType,
                    FROM_UNIXTIME(sg.date_start) as date_played,
                    sg.date_start,
                    sg.date_end,
                    sg.campaignID,
                    sg.map,
                    sg.difficulty,
                    sg.gamemode,
                    -- Calculate fields for MVP compatibility using stats_games data
                    (COALESCE(sg.boomer_kills,0) + COALESCE(sg.smoker_kills,0) + 
                     COALESCE(sg.jockey_kills,0) + COALESCE(sg.hunter_kills,0) + 
                     COALESCE(sg.spitter_kills,0) + COALESCE(sg.charger_kills,0)) as SpecialInfectedKills,
                    sg.SurvivorFFCount,
                    sg.ZombieKills,
                    sg.DamageTaken,
                    sg.SurvivorDamage,
                    sg.Deaths,
                    sg.Incaps,
                    sg.MedkitsUsed,
                    sg.MeleeKills,
                    (sg.MolotovsUsed + sg.PipebombsUsed + sg.BoomerBilesUsed) as TotalThrowables,
                    (sg.PillsUsed + sg.AdrenalinesUsed) as TotalPillsShots,
                    -- Individual throwable/consumable data for MVP calculation
                    sg.MolotovsUsed as throws_molotov,
                    sg.PipebombsUsed as throws_pipe,
                    sg.BoomerBilesUsed as throws_puke,
                    sg.PillsUsed as pills_used,
                    sg.AdrenalinesUsed as adrenaline_used,
                    -- Additional MVP factors from stats_games (using available fields)
                    0 as tanks_killed,
                    0 as kills_witch,
                    0 as ff_kills,
                    sg.ReviveOtherCount as revived_others,
                    sg.DefibrillatorsUsed as defibs_used,
                    0 as finales_won
                FROM stats_games sg
                INNER JOIN stats_users su ON sg.steamid = su.steamid
                INNER JOIN map_info mi ON sg.map = mi.mapid
                WHERE sg.map = ? OR sg.campaignID LIKE CONCAT(?, '%')
                ORDER BY ${orderBy}`
                params = [mapId, req.params.id.substring(0,8)]
            }
            
            const [rows] = await pool.query(query, params)
            
            // Use the already loaded calculationRules from the top level
            
            // Calculate MVP points for each user using the same logic as sessions API
            const pointValues = calculationRules.point_values || {
                positive_actions: {
                    common_kill: 1, special_kill: 6, tank_kill_max: 100, witch_kill: 15,
                    heal_teammate: 40, revive_teammate: 25, defib_teammate: 30, finale_win: 1000,
                    molotov_use: 5, pipe_use: 5, bile_use: 5, pill_use: 10, adrenaline_use: 15
                },
                penalties: { teammate_kill: -100 }
            };
            
            // Calculate average damage taken for bonus calculation
            const totalDamageTaken = rows.reduce((sum, row) => sum + (row.DamageTaken || 0), 0);
            const avgDamageTaken = rows.length > 0 ? totalDamageTaken / rows.length : 0;
            
            // Calculate MVP points for each user using comprehensive criteria
            rows.forEach(row => {
                let mvpPoints = 0;
                
                // Positive actions (using corrected data from stats_map_users)
                mvpPoints += (row.SpecialInfectedKills || 0) * (pointValues.positive_actions.special_kill || 6);
                mvpPoints += (row.ZombieKills || 0) * (pointValues.positive_actions.common_kill || 1);
                mvpPoints += (row.tanks_killed || 0) * (pointValues.positive_actions.tank_kill_max || 100);
                mvpPoints += (row.kills_witch || 0) * (pointValues.positive_actions.witch_kill || 15);
                mvpPoints += (row.MedkitsUsed || 0) * (pointValues.positive_actions.heal_teammate || 40);
                mvpPoints += (row.revived_others || 0) * (pointValues.positive_actions.revive_teammate || 25);
                mvpPoints += (row.defibs_used || 0) * (pointValues.positive_actions.defib_teammate || 30);
                mvpPoints += (row.finales_won || 0) * (pointValues.positive_actions.finale_win || 1000);
                
                // Additional positive actions
                mvpPoints += (row.throws_molotov || 0) * (pointValues.positive_actions.molotov_use || 5);
                mvpPoints += (row.throws_pipe || 0) * (pointValues.positive_actions.pipe_use || 5);
                mvpPoints += (row.throws_puke || 0) * (pointValues.positive_actions.bile_use || 5);
                mvpPoints += (row.pills_used || 0) * (pointValues.positive_actions.pill_use || 10);
                mvpPoints += (row.adrenaline_used || 0) * (pointValues.positive_actions.adrenaline_use || 15);
                
                // Penalties
                mvpPoints += (row.ff_kills || 0) * (pointValues.penalties.teammate_kill || -100);
                mvpPoints -= (row.SurvivorDamage || 0) * 2; // -2 per friendly fire damage
                
                // Damage taken bonus (reward for taking less damage than average)
                const damageTakenBonus = Math.max(0, (avgDamageTaken - (row.DamageTaken || 0)) * 0.5);
                mvpPoints += damageTakenBonus;
                
                row.mvpPoints = Math.round(mvpPoints);
                row.SurvivorFFCount = Math.round((row.SurvivorDamage || 0) / 10); // Estimate for display
            });
            
            // Sort users by MVP points to determine overall MVP
            const sortedUsers = [...rows].sort((a, b) => (b.mvpPoints || 0) - (a.mvpPoints || 0));
            
            // Mark the overall MVP (highest MVP points)
            if (sortedUsers.length > 0) {
                const mvpSteamId = sortedUsers[0].steamid;
                rows.forEach(row => {
                    if (row.steamid === mvpSteamId) {
                        row.isMVP = true;
                    }
                });
            }
            
            res.json(rows)
        }catch(err) {
            console.error('[/api/campaigns/:id]',err.message);
            res.status(500).json({error:"Internal Server Error"})
        }
    })
    router.get('/', routeCache.cacheSeconds(calculationRules.cache_durations?.campaign_list || 60), async(req,res) => {
        try {
            let perPage = parseInt(req.query.perPage) || calculationRules.pagination?.campaigns_per_page || 4;
            if(perPage > (calculationRules.pagination?.max_per_page || 100)) perPage = calculationRules.pagination?.max_per_page || 100;
            const selectedPage = req.query.page || 0
            const pageNumber = (isNaN(selectedPage) || selectedPage <= 0) ? 0 : (parseInt(selectedPage) - 1);
            const offset = pageNumber * perPage;

            const difficulty         = isNaN(req.query.difficulty) ? null : parseInt(req.query.difficulty)
            let selectTag            = req.query.tag
            if(!selectTag) selectTag = "any"
            let gamemodeSearchString = req.query.gamemode && req.query.gamemode !== "all" ? `${req.query.gamemode}` : calculationRules.defaults?.gamemode_search_all || `%`
            let mapSearchString      = "" // RLIKE "^c[0-9]m"
            if(req.query.type) {
                const officialPattern = calculationRules.map_classification?.official_map_pattern || "^c[0-9]+m"
                if(req.query.type.toLowerCase() === "official") mapSearchString = `AND map RLIKE "${officialPattern}"`
                else if(req.query.type.toLowerCase() === "custom") mapSearchString = `AND map NOT RLIKE "${officialPattern}"`
            }

            const [total] = await pool.execute("SELECT COUNT(DISTINCT campaignID) as total FROM `stats_games`")
            const [recent] = await pool.execute(`
                SELECT COUNT(g.campaignID) as playerCount,
                    g.campaignID,
                    g.map,
                    MIN(g.date_start) as date_start,
                    MAX(g.date_end) as date_end,
                    AVG(g.duration) * 60 as duration_seconds,
                    difficulty,
                    gamemode,
                    SUM(g.ZombieKills) as CommonsKilled,
                    SUM(g.SurvivorFFDamage) as FF,
                    SUM(g.Deaths) as Deaths,
                    SUM(g.MedkitsUsed) as MedkitsUsed,
                    SUM(COALESCE(g.boomer_kills, 0) + COALESCE(g.smoker_kills, 0) + COALESCE(g.jockey_kills, 0) + COALESCE(g.hunter_kills, 0) + COALESCE(g.spitter_kills, 0) + COALESCE(g.charger_kills, 0)) as SpecialInfectedKills,
                    (SUM(g.MolotovsUsed) + SUM(g.PipebombsUsed) + SUM(g.BoomerBilesUsed)) as ThrowableTotal,
                    server_tags,
                    COALESCE(i.name, g.map) as map_name
                FROM \`stats_games\` as g
                INNER JOIN \`stats_users\` ON g.steamid = \`stats_users\`.steamid
                LEFT JOIN map_info i ON i.mapid = g.map
                WHERE (? = 'any' OR server_tags IS NULL OR server_tags = '' OR FIND_IN_SET(?, server_tags)) ${mapSearchString} AND gamemode LIKE ? AND (? IS NULL OR difficulty = ?)
                GROUP BY g.campaignID
                ORDER BY MAX(g.date_end) DESC LIMIT ?, ?`,
            [selectTag, selectTag, gamemodeSearchString, difficulty, difficulty, offset, perPage])

            // For each campaign, check if we have stats_map_users data and use it if available
            for (let campaign of recent) {
                if (campaign.map) {
                    const [mapUserStats] = await pool.execute(`
                        SELECT
                            COUNT(DISTINCT smu.steamid) as playerCount,
                            MIN(smu.session_start) as date_start,
                            MAX(smu.session_end) as date_end,
                            SUM(smu.session_end - smu.session_start) as duration_seconds,
                            SUM(smu.common_kills) as CommonsKilled,
                            SUM(smu.survivor_damage_give) as FF,
                            SUM(smu.survivor_deaths) as Deaths,
                            SUM(smu.heal_others) as MedkitsUsed,
                            SUM(COALESCE(smu.kills_boomer,0) + COALESCE(smu.kills_smoker,0) +
                                COALESCE(smu.kills_jockey,0) + COALESCE(smu.kills_hunter,0) +
                                COALESCE(smu.kills_spitter,0) + COALESCE(smu.kills_charger,0)) as SpecialInfectedKills,
                            SUM(COALESCE(smu.throws_molotov,0) + COALESCE(smu.throws_pipe,0) + COALESCE(smu.throws_puke,0)) as ThrowableTotal
                        FROM stats_map_users smu
                        WHERE smu.mapid = ?
                    `, [campaign.map])

                    // If we have map user stats, use them instead of stats_games data
                    if (mapUserStats.length > 0 && mapUserStats[0].playerCount > 0) {
                        const mapStats = mapUserStats[0]
                        campaign.playerCount = mapStats.playerCount
                        campaign.date_start = mapStats.date_start
                        campaign.date_end = mapStats.date_end
                        campaign.duration_seconds = mapStats.duration_seconds?.toString() || campaign.duration_seconds
                        campaign.CommonsKilled = mapStats.CommonsKilled?.toString() || "0"
                        campaign.FF = mapStats.FF?.toString() || "0"
                        campaign.Deaths = mapStats.Deaths?.toString() || "0"
                        campaign.MedkitsUsed = mapStats.MedkitsUsed?.toString() || "0"
                        campaign.SpecialInfectedKills = mapStats.SpecialInfectedKills?.toString() || "0"
                        campaign.ThrowableTotal = mapStats.ThrowableTotal?.toString() || "0"
                    }
                }
            }

            // Calculate MVP points for each campaign using the updated data
            recent.forEach(campaign => {
                let mvpPoints = 0;

                // Enhanced MVP calculation using comprehensive criteria
                const pointValues = {
                    positive_actions: {
                        special_kill: 6, common_kill: 1, tank_kill_max: 100, witch_kill: 15,
                        heal_teammate: 40, revive_teammate: 25, defib_teammate: 30, finale_win: 1000,
                        molotov_use: 5, pipe_use: 5, bile_use: 5, pill_use: 10, adrenaline_use: 15
                    },
                    penalties: { teammate_kill: -100, ff_damage_multiplier: -2 }
                };

                // Positive actions
                mvpPoints += parseInt(campaign.SpecialInfectedKills || 0) * pointValues.positive_actions.special_kill;
                mvpPoints += parseInt(campaign.CommonsKilled || 0) * pointValues.positive_actions.common_kill;
                mvpPoints += parseInt(campaign.MedkitsUsed || 0) * pointValues.positive_actions.heal_teammate;
                mvpPoints += parseInt(campaign.ThrowableTotal || 0) * pointValues.positive_actions.molotov_use; // Average throwable value

                // Penalties for friendly fire
                mvpPoints += parseInt(campaign.FF || 0) * pointValues.penalties.ff_damage_multiplier;

                campaign.mvpPoints = Math.round(mvpPoints);
            });

            res.json({
                meta: {
                    selectTag,
                    gamemodeSearchString,
                    mapSearchString,
                    difficulty
                },
                recentCampaigns: recent,
                total_campaigns: total[0].total
            })
        }catch(err) {
            console.error('[/api/campaigns]',err.stack);
            res.status(500).json({error:"Internal Server Error"})
        }
    })
    
    // New endpoint: Get user statistics for a specific map
    router.get('/maps/:mapid/users', routeCache.cacheSeconds(120), async(req, res) => {
        try {
            const mvpCriteria = calculationRules.mvp_calculation?.criteria || [
                { field: "SpecialInfectedKills", direction: "desc" },
                { field: "SurvivorFFCount", direction: "asc" },
                { field: "ZombieKills", direction: "desc" },
                { field: "DamageTaken", direction: "asc" },
                { field: "SurvivorDamage", direction: "asc" }
            ]
            const orderBy = mvpCriteria.map(c => `${c.field} ${c.direction}`).join(', ')
            
            const [users] = await pool.query(`
                SELECT 
                    smu.*,
                    su.last_alias,
                    su.points,
                    mi.name as map_name,
                    mi.chapter_count,
                    FROM_UNIXTIME(smu.session_start) as session_start_time,
                    FROM_UNIXTIME(smu.session_end) as session_end_time,
                    -- Calculate fields for MVP compatibility
                    (COALESCE(smu.kills_boomer,0) + COALESCE(smu.kills_smoker,0) + 
                     COALESCE(smu.kills_jockey,0) + COALESCE(smu.kills_hunter,0) + 
                     COALESCE(smu.kills_spitter,0) + COALESCE(smu.kills_charger,0)) as SpecialInfectedKills,
                    smu.survivor_ff as SurvivorFFCount,
                    smu.common_kills as ZombieKills,
                    smu.survivor_damage_rec as DamageTaken,
                    smu.survivor_damage_give as SurvivorDamage
                FROM stats_map_users smu
                JOIN stats_users su ON smu.steamid = su.steamid
                LEFT JOIN map_info mi ON mi.mapid = smu.mapid
                WHERE smu.mapid = ?
                ORDER BY ${orderBy}
            `, [req.params.mapid])
            
            res.json({ users })
        } catch(err) {
            console.error('[/api/campaigns/maps/:mapid/users]', err.message)
            res.status(500).json({error: "Internal Server Error"})
        }
    })
    
    // New endpoint: Get map statistics for a specific user
    router.get('/users/:steamid/maps', routeCache.cacheSeconds(120), async(req, res) => {
        try {
            const [mapStats] = await pool.query(`
                SELECT 
                    smu.*,
                    mi.name as map_name,
                    mi.chapter_count,
                    FROM_UNIXTIME(smu.session_start) as session_start_time,
                    FROM_UNIXTIME(smu.session_end) as session_end_time,
                    -- Calculate derived fields
                    (COALESCE(smu.kills_boomer,0) + COALESCE(smu.kills_smoker,0) + 
                     COALESCE(smu.kills_jockey,0) + COALESCE(smu.kills_hunter,0) + 
                     COALESCE(smu.kills_spitter,0) + COALESCE(smu.kills_charger,0)) as SpecialInfectedKills
                FROM stats_map_users smu
                LEFT JOIN map_info mi ON mi.mapid = smu.mapid
                WHERE smu.steamid = ?
                ORDER BY smu.session_start DESC
            `, [req.params.steamid])
            
            res.json({ mapStats })
        } catch(err) {
            console.error('[/api/campaigns/users/:steamid/maps]', err.message)
            res.status(500).json({error: "Internal Server Error"})
        }
    })
    
    // New endpoint: Get campaign details for a specific map
    router.get('/map/:mapId', routeCache.cacheSeconds(120), async(req, res) => {
        try {
            const mapId = req.params.mapId;

            // Validate mapId parameter
            if (!mapId || mapId.trim() === '') {
                return res.status(400).json({
                    error: "INVALID_MAP_ID",
                    message: "Map ID is required"
                });
            }

            // Get map information
            const [mapInfo] = await pool.query(`
                SELECT mapid, name, chapter_count, flags
                FROM map_info
                WHERE mapid = ?
            `, [mapId]);

            if (mapInfo.length === 0) {
                return res.status(404).json({
                    error: "MAP_NOT_FOUND",
                    message: "Map not found"
                });
            }

            // Get all player statistics for this map
            const [playerStats] = await pool.query(`
                SELECT
                    smu.steamid,
                    smu.last_alias,
                    smu.mapid,
                    smu.session_start,
                    smu.session_end,
                    NULL as ping,
                    smu.common_kills,
                    smu.melee_kills,
                    smu.survivor_damage_rec as damage_taken,
                    smu.survivor_ff as friendly_fire_count,
                    smu.survivor_ff_rec as friendly_fire_damage,
                    smu.throws_molotov as molotovs_used,
                    smu.throws_pipe as pipebombs_used,
                    smu.boomer_mellos as biles_used,
                    (smu.heal_others + smu.heal_self) as kits_used,
                    smu.survivor_incaps as incaps,
                    smu.survivor_deaths as deaths,
                    smu.clowns_honked as total_honks,
                    -- Calculate special infected kills
                    CAST((COALESCE(smu.kills_boomer,0) + COALESCE(smu.kills_smoker,0) +
                     COALESCE(smu.kills_jockey,0) + COALESCE(smu.kills_hunter,0) +
                     COALESCE(smu.kills_spitter,0) + COALESCE(smu.kills_charger,0)) AS UNSIGNED) as specials_killed,
                    -- Format session times
                    FROM_UNIXTIME(smu.session_start) as session_start_formatted,
                    FROM_UNIXTIME(smu.session_end) as session_end_formatted,
                    -- Calculate session duration in minutes
                    CASE
                        WHEN smu.session_end > smu.session_start
                        THEN ROUND((smu.session_end - smu.session_start) / 60, 1)
                        ELSE NULL
                    END as session_duration_minutes
                FROM stats_map_users smu
                WHERE smu.mapid = ?
                ORDER BY smu.session_start DESC
            `, [mapId]);

            // Calculate aggregated statistics
            const aggregatedStats = {
                total_players: playerStats.length,
                total_zombies_killed: 0,
                total_specials_killed: 0,
                total_melee_kills: 0,
                total_damage_taken: 0,
                total_friendly_fire_count: 0,
                total_friendly_fire_damage: 0,
                total_molotovs_used: 0,
                total_pipebombs_used: 0,
                total_biles_used: 0,
                total_kits_used: 0,
                total_incaps: 0,
                total_deaths: 0,
                total_honks: 0,
                avg_ping: 0,
                avg_session_duration: 0
            };

            let totalPing = 0;
            let totalDuration = 0;
            let validPingCount = 0;
            let validDurationCount = 0;

            playerStats.forEach(player => {
                aggregatedStats.total_zombies_killed += parseInt(player.common_kills) || 0;
                aggregatedStats.total_specials_killed += parseInt(player.specials_killed) || 0;
                aggregatedStats.total_melee_kills += parseInt(player.melee_kills) || 0;
                aggregatedStats.total_damage_taken += parseInt(player.damage_taken) || 0;
                aggregatedStats.total_friendly_fire_count += parseInt(player.friendly_fire_count) || 0;
                aggregatedStats.total_friendly_fire_damage += parseInt(player.friendly_fire_damage) || 0;
                aggregatedStats.total_molotovs_used += parseInt(player.molotovs_used) || 0;
                aggregatedStats.total_pipebombs_used += parseInt(player.pipebombs_used) || 0;
                aggregatedStats.total_biles_used += parseInt(player.biles_used) || 0;
                aggregatedStats.total_kits_used += parseInt(player.kits_used) || 0;
                aggregatedStats.total_incaps += parseInt(player.incaps) || 0;
                aggregatedStats.total_deaths += parseInt(player.deaths) || 0;
                aggregatedStats.total_honks += parseInt(player.total_honks) || 0;

                // Skip ping calculation since it's not available in stats_map_users
                // if (player.ping && player.ping > 0) {
                //     totalPing += player.ping;
                //     validPingCount++;
                // }

                if (player.session_duration_minutes && player.session_duration_minutes > 0) {
                    totalDuration += player.session_duration_minutes;
                    validDurationCount++;
                }
            });

            // Calculate averages
            aggregatedStats.avg_ping = 0; // Not available in stats_map_users
            aggregatedStats.avg_session_duration = validDurationCount > 0 ?
                Math.round((totalDuration / validDurationCount) * 10) / 10 : 0;

            res.json({
                map: mapInfo[0],
                aggregated_stats: aggregatedStats,
                player_stats: playerStats
            });

        } catch(err) {
            console.error('[/api/campaigns/map/:mapId]', err.stack);
            res.status(500).json({
                error: "INTERNAL_SERVER_ERROR",
                message: "Failed to fetch map campaign details"
            });
        }
    });

    return router;
}