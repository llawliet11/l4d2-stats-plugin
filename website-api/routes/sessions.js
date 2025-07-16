import Router from 'express'
const router = Router()
import routeCache from 'route-cache'
import fs from 'fs'
import path from 'path'
import MVPCalculator from '../services/MVPCalculator.js'

export default function(pool) {
    router.get('/', routeCache.cacheSeconds(120), async(req,res) => {
        try {
            let perPage = parseInt(req.query.perPage) || 10;
            if(perPage > 100) perPage = 100;
            const selectedPage = req.query.page || 0
            const pageNumber = (isNaN(selectedPage) || selectedPage <= 0) ? 0 : (parseInt(selectedPage) - 1);
            const offset = pageNumber * perPage;
            
            // Get user aggregated stats with all data needed for MVP calculation
            const [rows] = await pool.query(`
                SELECT
                    u.steamid,
                    u.last_alias,
                    u.points,
                    u.survivor_deaths,
                    u.survivor_incaps,
                    u.survivor_ff,
                    u.survivor_ff_rec,
                    u.survivor_damage_rec,
                    u.common_kills,
                    (u.kills_smoker + u.kills_boomer + u.kills_hunter + u.kills_spitter + u.kills_jockey + u.kills_charger) as special_infected_kills,
                    u.heal_others,
                    (u.throws_molotov + u.throws_pipe + u.throws_puke) as total_throwables,
                    (u.pills_used + u.adrenaline_used) as total_pills_shots,
                    u.tanks_killed,
                    u.kills_witch,
                    u.ff_kills,
                    u.revived_others,
                    u.defibs_used,
                    u.finales_won,
                    u.throws_molotov,
                    u.throws_pipe,
                    u.throws_puke,
                    u.pills_used,
                    u.adrenaline_used,
                    'N/A' as map,
                    'Overall' as difficulty
                FROM stats_users u
                WHERE u.points > 0
                ORDER BY u.points DESC
                LIMIT ?,?
            `, [offset, perPage]);
            
            const [total] = await pool.execute("SELECT COUNT(*) AS total_sessions FROM stats_users WHERE points > 0");

            // Calculate MVP using the centralized MVP calculator
            MVPCalculator.calculateAndMarkMVP(rows);
            
            return res.json({
                sessions: rows,
                total_sessions: total[0].total_sessions,
            })
        }catch(err) {
            console.error('/api/sessions',err.message)
            res.status(500).json({error:'Internal Server Error'})
        }
    })
    router.get('/:session', routeCache.cacheSeconds(120), async(req,res) => {
        try {
            const sessId = parseInt(req.params.session);
            if(isNaN(sessId)) {
                res.status(422).json({error: "Session ID is not a valid number."})
            }else{
                const [row] = await pool.query("SELECT `stats_games`.*,last_alias,points FROM `stats_games` INNER JOIN `stats_users` ON `stats_games`.steamid = `stats_users`.steamid WHERE `stats_games`.`id`=?", [req.params.session])
                if(row.length > 0) {
                    let users = [];
                    if(row[0].campaignID) {
                        // Load MVP calculation rules
                        let calculationRules;
                        try {
                            const rulesPath = path.join(process.cwd(), 'config', 'calculation-rules.json');
                            const rulesData = fs.readFileSync(rulesPath, 'utf8');
                            calculationRules = JSON.parse(rulesData);
                        } catch (err) {
                            console.warn('[/api/sessions/:session] Could not load calculation rules, using defaults:', err.message);
                            calculationRules = {
                                mvp_calculation: {
                                    criteria: [
                                        { field: "SpecialInfectedKills", direction: "desc" },
                                        { field: "SurvivorFFCount", direction: "asc" },
                                        { field: "ZombieKills", direction: "desc" },
                                        { field: "DamageTaken", direction: "asc" },
                                        { field: "SurvivorDamage", direction: "asc" }
                                    ]
                                }
                            };
                        }

                        // Build MVP sorting criteria from config
                        const mvpCriteria = calculationRules.mvp_calculation?.criteria || [
                            { field: "SpecialInfectedKills", direction: "desc" },
                            { field: "SurvivorFFCount", direction: "asc" },
                            { field: "ZombieKills", direction: "desc" },
                            { field: "DamageTaken", direction: "asc" },
                            { field: "SurvivorDamage", direction: "asc" }
                        ]
                        const orderBy = mvpCriteria.map(c => `${c.field} ${c.direction}`).join(', ')
                        
                        // Get campaign participants with MVP ranking
                        const [userlist] = await pool.query(`
                            SELECT 
                                stats_games.id,
                                stats_users.steamid,
                                stats_users.last_alias,
                                stats_games.points,
                                stats_games.SpecialInfectedKills,
                                stats_games.SurvivorFFCount,
                                stats_games.ZombieKills,
                                stats_games.DamageTaken,
                                stats_games.SurvivorDamage
                            FROM stats_games 
                            INNER JOIN stats_users ON stats_users.steamid = stats_games.steamid 
                            WHERE campaignID = ? 
                            ORDER BY ${orderBy}
                        `, [row[0].campaignID])
                        
                        // Mark the first player as MVP
                        users = userlist.map((user, index) => ({
                            ...user,
                            isMVP: index === 0
                        }));
                    }
                    res.json({session: row[0], users})
                } else 
                    res.json({sesssion: null, users: [], not_found: true})
            }
           
        }catch(err) {
            console.error('/api/sessions/:session',err.message)
            res.status(500).json({error:'Internal Server Error'})
        }
    })
    return router;
}