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
            
            // Get user aggregated stats with all data needed for MVP calculation
            const [rows] = await pool.query(`
                SELECT 
                    u.steamid,
                    u.last_alias,
                    u.points,
                    u.survivor_deaths as Deaths,
                    u.survivor_incaps as Incaps,
                    u.survivor_ff as SurvivorDamage,
                    u.survivor_damage_rec as DamageTaken,
                    u.common_kills as ZombieKills,
                    (u.kills_smoker + u.kills_boomer + u.kills_hunter + u.kills_spitter + u.kills_jockey + u.kills_charger) as SpecialInfectedKills,
                    u.heal_others as MedkitsUsed,
                    (u.throws_molotov + u.throws_pipe + u.throws_puke) as TotalThrowables,
                    (u.pills_used + u.adrenaline_used) as TotalPillsShots,
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
            
            // Load MVP calculation rules for overall MVP
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

            // Calculate MVP points for each user based on comprehensive criteria
            const pointValues = calculationRules.point_values || {
                positive_actions: {
                    common_kill: 1, special_kill: 6, tank_kill_max: 100, witch_kill: 15,
                    heal_teammate: 40, revive_teammate: 25, defib_teammate: 30, finale_win: 1000
                },
                penalties: { teammate_kill: -100 }
            };

            // Calculate average damage taken for bonus calculation
            const totalDamageTaken = rows.reduce((sum, row) => sum + (row.DamageTaken || 0), 0);
            const avgDamageTaken = rows.length > 0 ? totalDamageTaken / rows.length : 0;

            // Calculate MVP points for each user using real data
            rows.forEach(row => {
                let mvpPoints = 0;
                
                // Positive actions (using real data from stats_users)
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