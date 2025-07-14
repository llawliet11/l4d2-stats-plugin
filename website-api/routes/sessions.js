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
            
            // Get sessions for display - these are individual session records for the table
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
            
            // Get unique campaigns from the current page sessions
            const uniqueCampaigns = [...new Set(rows.filter(r => r.campaignID).map(r => r.campaignID))];
            
            // For each campaign, get aggregated user stats and determine MVP
            const campaignMVPs = {};
            
            for (const campaignID of uniqueCampaigns) {
                // Get aggregated stats for all users in this campaign
                const orderBy = mvpCriteria.map(c => `${c.field} ${c.direction}`).join(', ');
                const [campaignStats] = await pool.query(`
                    SELECT 
                        steamid,
                        SUM(SpecialInfectedKills) as SpecialInfectedKills,
                        SUM(SurvivorFFCount) as SurvivorFFCount, 
                        SUM(ZombieKills) as ZombieKills,
                        SUM(DamageTaken) as DamageTaken,
                        SUM(SurvivorDamage) as SurvivorDamage
                    FROM stats_games 
                    WHERE campaignID = ? 
                    GROUP BY steamid 
                    ORDER BY ${orderBy}
                `, [campaignID]);
                
                // The first user in the sorted result is the MVP for this campaign
                if (campaignStats.length > 0) {
                    campaignMVPs[campaignID] = campaignStats[0].steamid;
                }
            }
            
            // Mark sessions where the user is MVP for their campaign
            rows.forEach(session => {
                if (session.campaignID && campaignMVPs[session.campaignID] === session.steamid) {
                    session.isMVP = true;
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