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
            
            const [rows] = await pool.query(
                `SELECT \`stats_games\`.*, last_alias, points, i.name as map_name FROM \`stats_games\` INNER JOIN \`stats_users\` ON \`stats_games\`.steamid = \`stats_users\`.steamid INNER JOIN map_info i ON i.mapid = stats_games.map WHERE left(\`stats_games\`.campaignID, 8) = ? ORDER BY ${orderBy}`, 
                [req.params.id.substring(0,8)]
            )
            res.json(rows)
        }catch(err) {
            console.error('[/api/user/:user]',err.message);
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
                    g.date_start, 
                    g.date_end, 
                    difficulty, 
                    gamemode,SUM(ZombieKills) as CommonsKilled, 
                    SUM(SurvivorDamage) as FF, 
                    SUM(Deaths) as Deaths, 
                    SUM(MedkitsUsed), 
                    (SUM(MolotovsUsed) + SUM(PipebombsUsed) + SUM(BoomerBilesUsed)) as ThrowableTotal, 
                    server_tags,
                    COALESCE(i.name, g.map) as map_name
                FROM \`stats_games\` as g 
                INNER JOIN \`stats_users\` ON g.steamid = \`stats_users\`.steamid 
                LEFT JOIN map_info i ON i.mapid = g.map
                WHERE (? = 'any' OR server_tags IS NULL OR server_tags = '' OR FIND_IN_SET(?, server_tags)) ${mapSearchString} AND gamemode LIKE ? AND (? IS NULL OR difficulty = ?)
                GROUP BY g.campaignID 
                ORDER BY date_end DESC LIMIT ?, ?`, 
            [selectTag, selectTag, gamemodeSearchString, difficulty, difficulty, offset, perPage])
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
    
    return router;
}