import Router from 'express'
const router = Router()
import routeCache from 'route-cache'

export default function(pool) {
    router.get('/info', routeCache.cacheSeconds(120), async(req,res) => {
        try {
            const [totals] = await pool.execute("SELECT (SELECT COUNT(*) FROM `stats_users`) AS total_users, (SELECT COUNT(*) FROM `stats_games`) AS total_sessions");
            res.json({
                ...totals[0]
            });
        }catch(err) {
            console.error('[/api/top]',err.message);
            res.status(500).json({error:"Internal Server Error"})
        }
    })
    //TODO: Rewrite to /user/:user/search or GET /user/:user
    router.get('/search/:user', async(req,res) => {
        try {
            //TODO: add top_gamemode
            if(!req.params.user) return res.status(404).json([])
            const searchQuery = `%${req.params.user}%`;
            const [rows] = await pool.query("SELECT steamid,last_alias,minutes_played,last_join_date,points FROM `stats_users` WHERE `last_alias` LIKE ? LIMIT 20", [ searchQuery ])
            res.json(rows);
        }catch(err) {
            console.error('[/api/search/:user]', err.message);
            res.status(500).json({error:"Internal Server Error"})
        }
    })

    router.get('/totals', routeCache.cacheSeconds(300), async(req,res) => {
        try {
            const [totals] = await pool.execute(`SELECT
            sum(nullif(finale_time,0)) as finale_time,
            sum(CASE WHEN date_end > 0 AND date_start > 0 THEN date_end - date_start ELSE 0 END) as game_duration,
            sum(nullif(ZombieKills,0)) as zombie_kills,
            sum(nullif(SurvivorDamage,0)) as survivor_ff,
            sum(MedkitsUsed) as MedkitsUsed,
            sum(FirstAidShared) as FirstAidShared,
            sum(PillsUsed) as PillsUsed,
            sum(AdrenalinesUsed) as AdrenalinesUsed,
            sum(MolotovsUsed) as MolotovsUsed,
            sum(PipebombsUsed) as PipebombsUsed,
            sum(BoomerBilesUsed) as BoomerBilesUsed,
            sum(DamageTaken) as DamageTaken,
            sum(MeleeKills) as MeleeKills,
            sum(ReviveOtherCount) as ReviveOtherCount,
            sum(DefibrillatorsUsed) as DefibrillatorsUsed,
            sum(Deaths) as Deaths,
            sum(Incaps) as Incaps,
            sum(nullif(boomer_kills,0)) as boomer_kills,
            sum(nullif(jockey_kills,0)) as jockey_kills,
            sum(nullif(smoker_kills,0)) as smoker_kills,
            sum(nullif(spitter_kills,0)) as spitter_kills,
            sum(nullif(hunter_kills,0)) as hunter_kills,
            sum(nullif(charger_kills,0)) as charger_kills,
            (SELECT COUNT(*) FROM \`stats_games\`) AS total_sessions,
            (SELECT COUNT(distinct(campaignID)) from stats_games) AS total_games,
            (SELECT COUNT(*) FROM \`stats_users\`) AS total_users
            FROM stats_games WHERE date_start > 0 AND date_end > 0`)
            const [mapTotals] = await pool.execute("SELECT map,COUNT(*) as count FROM stats_games GROUP BY map ORDER BY COUNT(map) DESC")
            if(totals.length == 0) {
                return res.status(500).json({error:'Internal Server Error'})
            }else{
                let stats = {}, maps = {};
                for(const key in totals[0]) {
                    stats[key] = parseInt(totals[0][key])
                }
                mapTotals.forEach(({map,count}) => {
                    maps[map] = count;
                })
                res.json({
                    stats,
                    maps
                })
            }
        }catch(err) {
            console.error('/api/totals',err.message)
            res.status(500).json({error:'Internal Server Error'})
        }
    })
    router.get('/summary', routeCache.cacheSeconds(300), async(req,res) => {
        try {
            const [maps] = await pool.execute("SELECT map FROM stats_games WHERE map RLIKE \"^c[0-9]m\" GROUP BY map ORDER BY COUNT(map) DESC")
            const [userCount] = await pool.execute("SELECT AVG(games.players) as avgPlayers FROM (SELECT COUNT(campaignID) as players FROM stats_games GROUP BY `campaignID`) as games")
            const [topStats] = await pool.execute(`SELECT
            avg(nullif(finale_time,0)) as finale_time,
            avg(CASE WHEN date_end > 0 AND date_start > 0 THEN date_end - date_start ELSE 0 END) as game_duration,
            avg(nullif(ZombieKills,0)) as zombie_kills,
            avg(nullif(SurvivorDamage,0)) as survivor_ff,
            avg(MedkitsUsed) as MedkitsUsed,
            avg(FirstAidShared) as FirstAidShared,
            avg(PillsUsed) as PillsUsed,
            avg(AdrenalinesUsed) as AdrenalinesUsed,
            avg(MolotovsUsed) as MolotovsUsed,
            avg(PipebombsUsed) as PipebombsUsed,
            avg(BoomerBilesUsed) as BoomerBilesUsed,
            avg(DamageTaken) as DamageTaken,
            avg(difficulty) as difficulty,
            avg(MeleeKills) as MeleeKills,
            avg(ping) as ping,
            avg(ReviveOtherCount) as ReviveOtherCount,
            avg(DefibrillatorsUsed) as DefibrillatorsUsed,
            avg(Deaths) as Deaths,
            avg(Incaps) as Incaps,
            avg(nullif(boomer_kills,0)) as boomer_kills,
            avg(nullif(jockey_kills,0)) as jockey_kills,
            avg(nullif(smoker_kills,0)) as smoker_kills,
            avg(nullif(spitter_kills,0)) as spitter_kills,
            avg(nullif(hunter_kills,0)) as hunter_kills,
            avg(nullif(charger_kills,0)) as charger_kills
            FROM stats_games WHERE date_start > 0 AND date_end > 0`)
            let stats = {};
            if(topStats[0]) {
                for(const key in topStats[0]) {
                    if(key == "difficulty") {
                        stats[key] = Math.round(parseFloat(topStats[0][key]))
                    }else{
                        stats[key] = parseFloat(topStats[0][key])
                    }
                }
            }
            res.json({
                topMap: maps.length > 0 ? maps[0].map : null,
                bottomMap: maps.length > 0 ? maps[maps.length-1].map : null,
                averagePlayers: userCount.length > 0 ? Math.round(parseFloat(userCount[0].avgPlayers)) : 0,
                stats
            })
        }catch(err) {
            console.error('/api/summary',err.message)
            res.status(500).json({error:'Internal Server Error'})
        }
    })

    // New endpoint for database health check
    router.get('/health', routeCache.cacheSeconds(60), async(req,res) => {
        try {
            const [userStats] = await pool.execute(`
                SELECT
                    COUNT(*) as total_users,
                    COUNT(CASE WHEN minutes_played > 0 THEN 1 END) as active_users,
                    AVG(CASE WHEN minutes_played > 0 THEN minutes_played END) as avg_playtime,
                    MAX(last_join_date) as last_activity
                FROM stats_users
            `);

            const [sessionStats] = await pool.execute(`
                SELECT
                    COUNT(*) as total_sessions,
                    COUNT(CASE WHEN date_end > 0 AND date_start > 0 THEN 1 END) as valid_sessions,
                    AVG(CASE WHEN date_end > 0 AND date_start > 0 THEN (date_end - date_start) / 60 END) as avg_session_minutes
                FROM stats_games
            `);

            res.json({
                status: 'healthy',
                users: userStats[0],
                sessions: sessionStats[0],
                timestamp: new Date().toISOString()
            });
        } catch(err) {
            console.error('[/api/health]', err.message);
            res.status(500).json({
                status: 'unhealthy',
                error: 'Database connection failed',
                timestamp: new Date().toISOString()
            });
        }
    })

    return router;
}