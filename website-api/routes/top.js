import Router from 'express'
const router = Router()
import routeCache from 'route-cache'

export default function(pool) {
    router.get('/users/:page?', routeCache.cacheSeconds(30), async(req,res) => {
        try {
            const MAX_RESULTS = req.query.max_results ? parseInt(req.query.max_results) || 15 : 15;
    
            const selectedPage = req.params.page || 0;
            const pageNumber = (isNaN(selectedPage) || selectedPage <= 0) ? 0 : (parseInt(req.params.page) - 1);
            const offset = pageNumber * MAX_RESULTS;
            let rows, version
            if(req.query.version == "2") {
                // Legacy v2 - show all users including those with 0 or negative points
                [rows] = await pool.query(`SELECT
                     steamid,last_alias,minutes_played,last_join_date,points
                    FROM stats_users
                    WHERE minutes_played >= 0
                    ORDER BY points DESC, minutes_played DESC
                    LIMIT ?,?`,
                    [offset, MAX_RESULTS]
                )
                version = "v2"
            } else {
                // Default: Use corrected database points (v1) - show all users including 0/negative points
                [rows] = await pool.query("SELECT steamid,last_alias,minutes_played,last_join_date,points FROM `stats_users` WHERE minutes_played >= 0 ORDER BY `points` DESC, `minutes_played` DESC LIMIT ?,?", [offset, MAX_RESULTS])
                version = "v1"
            }
            res.json({
                users: rows,
                version
            });
        }catch(err) {
            console.error('[/api/top]',err.message);
            res.status(500).json({error:"Internal Server Error"})
        }
    })
    router.get('/stats', routeCache.cacheSeconds(300), async(req,res) => {
        try {
            const [deaths] = await pool.execute(`SELECT steamid,last_alias,points,survivor_deaths as value FROM \`stats_users\`  
                WHERE survivor_deaths > 0 ORDER BY \`stats_users\`.\`survivor_deaths\` desc, \`stats_users\`.\`points\` desc limit 10`, [])
            const [ffDamage] = await pool.execute(`SELECT steamid,last_alias,points,survivor_ff as value FROM \`stats_users\`  
                WHERE survivor_ff > 0 ORDER BY \`stats_users\`.\`survivor_ff\` desc, \`stats_users\`.\`points\` desc limit 10`, [])
            const [healOthers] = await pool.execute(`SELECT steamid,last_alias,points,heal_others as value FROM \`stats_users\`  
                WHERE heal_others > 0 ORDER BY \`stats_users\`.\`heal_others\` desc, \`stats_users\`.\`points\` desc limit 10`, [])
            const [revivedOthers] = await pool.execute(`SELECT steamid,last_alias,points,revived_others as value FROM \`stats_users\`  
                WHERE revived_others > 0 ORDER BY \`stats_users\`.\`revived_others\` desc, \`stats_users\`.\`points\` desc limit 10`, [])
            const [survivorIncaps] = await pool.execute(`SELECT steamid,last_alias,points,survivor_incaps as value FROM \`stats_users\`  
                WHERE survivor_incaps > 0 ORDER BY \`stats_users\`.\`survivor_incaps\` desc, \`stats_users\`.\`points\` desc limit 10`, []) 
            const [clownHonks] = await pool.execute(`SELECT steamid,last_alias,points,clowns_honked as value FROM \`stats_users\`  
            WHERE clowns_honked > 0 ORDER BY \`stats_users\`.\`clowns_honked\` desc, \`stats_users\`.\`points\` desc limit 10 `, [])
            const [timesMVP] = await pool.execute(`
                SELECT
                    stats_games.steamid,
                    su.last_alias as last_alias,
                    SUM(honks) as value
                FROM stats_games
                INNER JOIN stats_users as su
                    ON su.steamid = stats_games.steamid
                WHERE stats_games.honks > 0 AND stats_games.date_end < 1649344160
                GROUP BY stats_games.steamid
                ORDER by stats_games.honks DESC
                LIMIT 10
                `, []
            ) 

            res.json({
                deaths,
                ffDamage,
                healOthers,
                revivedOthers,
                survivorIncaps,
                clownHonks,
                timesMVP
            });
        }catch(err) {
            console.error('[/api/top]',err.message);
            res.status(500).json({error:"Internal Server Error"})
        }
    })
    
    // Cache clearing endpoint for debugging
    router.post('/clear-cache', async(req,res) => {
        try {
            // Clear route cache if available
            if(routeCache.removeCache) {
                routeCache.removeCache('/api/top/users');
                routeCache.removeCache('/api/top/stats');
            }
            res.json({success: true, message: 'Cache cleared'});
        } catch(err) {
            console.error('[/api/top/clear-cache]', err.message);
            res.status(500).json({error: 'Failed to clear cache'});
        }
    })
    
    return router;
}