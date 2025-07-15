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
                // Filter by session timeframe for campaign-specific stats
                query = `SELECT 
                    smu.*,
                    su.last_alias,
                    su.points,
                    mi.name as map_name,
                    -- Calculate fields for MVP compatibility
                    (COALESCE(smu.kills_boomer,0) + COALESCE(smu.kills_smoker,0) + 
                     COALESCE(smu.kills_jockey,0) + COALESCE(smu.kills_hunter,0) + 
                     COALESCE(smu.kills_spitter,0) + COALESCE(smu.kills_charger,0)) as SpecialInfectedKills,
                    smu.survivor_ff as SurvivorFFCount,
                    smu.common_kills as ZombieKills,
                    smu.survivor_damage_rec as DamageTaken,
                    smu.survivor_damage_give as SurvivorDamage,
                    smu.survivor_deaths as Deaths,
                    smu.survivor_incaps as Incaps,
                    smu.pills_used as MedkitsUsed,
                    (smu.pickups_pipe_bomb + smu.pickups_molotov + smu.throws_puke) as TotalThrowables,
                    smu.pickups_pain_pills as TotalPillsShots
                FROM stats_map_users smu
                INNER JOIN stats_users su ON smu.steamid = su.steamid
                INNER JOIN map_info mi ON smu.mapid = mi.mapid
                WHERE smu.mapid = ? AND smu.session_start >= ? AND smu.session_end <= ?
                ORDER BY ${orderBy}`
                params = [mapId, sessionStart, sessionEnd]
            } else {
                // Fallback to all map sessions if no specific timeframe
                query = `SELECT 
                    smu.*,
                    su.last_alias,
                    su.points,
                    mi.name as map_name,
                    -- Calculate fields for MVP compatibility
                    (COALESCE(smu.kills_boomer,0) + COALESCE(smu.kills_smoker,0) + 
                     COALESCE(smu.kills_jockey,0) + COALESCE(smu.kills_hunter,0) + 
                     COALESCE(smu.kills_spitter,0) + COALESCE(smu.kills_charger,0)) as SpecialInfectedKills,
                    smu.survivor_ff as SurvivorFFCount,
                    smu.common_kills as ZombieKills,
                    smu.survivor_damage_rec as DamageTaken,
                    smu.survivor_damage_give as SurvivorDamage,
                    smu.survivor_deaths as Deaths,
                    smu.survivor_incaps as Incaps,
                    smu.pills_used as MedkitsUsed,
                    (smu.pickups_pipe_bomb + smu.pickups_molotov + smu.throws_puke) as TotalThrowables,
                    smu.pickups_pain_pills as TotalPillsShots
                FROM stats_map_users smu
                INNER JOIN stats_users su ON smu.steamid = su.steamid
                INNER JOIN map_info mi ON smu.mapid = mi.mapid
                WHERE smu.mapid = ?
                ORDER BY ${orderBy}`
                params = [mapId]
            }
            
            const [rows] = await pool.query(query, params)
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

            // Calculate MVP points for each campaign
            recent.forEach(campaign => {
                let mvpPoints = 0;

                // Basic MVP calculation
                mvpPoints += (campaign.SpecialInfectedKills || 0) * 6;
                mvpPoints += (campaign.CommonsKilled || 0) * 1;
                mvpPoints += (campaign.MedkitsUsed || 0) * 40;

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
            console.error('[/api/user/:user]',err.stack);
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
    
    return router;
}