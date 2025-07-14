import Router from 'express'
const router = Router()
import routeCache from 'route-cache'
import fs from 'fs'
import path from 'path'

export default function(pool) {
    router.get('/', routeCache.cacheSeconds(120), async(req,res) => {
        try {
            let perPage = parseInt(req.query.perPage) || 10;
            if(perPage > 100) perPage = 100;
            const selectedPage = req.query.page || 0
            const pageNumber = (isNaN(selectedPage) || selectedPage <= 0) ? 0 : (parseInt(selectedPage) - 1);
            const offset = pageNumber * perPage;
            
            // Get sessions with MVP calculation
            const [rows] = await pool.query("SELECT `stats_games`.*,last_alias,points FROM `stats_games` INNER JOIN `stats_users` ON `stats_games`.steamid = `stats_users`.steamid order by `stats_games`.id desc LIMIT ?,?", [offset, perPage])
            const [total] = await pool.execute("SELECT COUNT(*)  AS total_sessions FROM `stats_games`");
            
            // Load MVP calculation rules
            let calculationRules;
            try {
                const rulesPath = path.join(process.cwd(), 'config', 'calculation-rules.json');
                const rulesData = fs.readFileSync(rulesPath, 'utf8');
                calculationRules = JSON.parse(rulesData);
            } catch (err) {
                console.warn('[/api/sessions] Could not load calculation rules, using defaults:', err.message);
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
            
            // Group sessions by campaignID and calculate MVP for each campaign
            const campaignGroups = {};
            rows.forEach(session => {
                if (session.campaignID) {
                    if (!campaignGroups[session.campaignID]) {
                        campaignGroups[session.campaignID] = [];
                    }
                    campaignGroups[session.campaignID].push(session);
                }
            });
            
            // Calculate MVP for each campaign
            Object.keys(campaignGroups).forEach(campaignID => {
                const campaignSessions = campaignGroups[campaignID];
                
                // Sort sessions by MVP criteria
                campaignSessions.sort((a, b) => {
                    for (const criterion of mvpCriteria) {
                        const fieldA = a[criterion.field] || 0;
                        const fieldB = b[criterion.field] || 0;
                        
                        if (criterion.direction === 'desc') {
                            if (fieldB !== fieldA) return fieldB - fieldA;
                        } else {
                            if (fieldA !== fieldB) return fieldA - fieldB;
                        }
                    }
                    return 0;
                });
                
                // Mark the first session (MVP) in each campaign
                if (campaignSessions.length > 0) {
                    campaignSessions[0].isMVP = true;
                }
            });
            
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