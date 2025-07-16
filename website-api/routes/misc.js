import Router from 'express'
const router = Router()
import routeCache from 'route-cache'
import fs from 'fs'
import path from 'path'
import PointCalculator from '../services/PointCalculator.js'

export default function(pool) {
    // Point system configuration endpoint
    router.get('/point-system', routeCache.cacheSeconds(300), async(req, res) => {
        try {
            const pointCalculator = new PointCalculator();
            const config = pointCalculator.getConfig();

            res.json({
                success: true,
                config: config,
                version: config.version,
                last_updated: config.last_updated
            });
        } catch (error) {
            console.error('[/api/point-system] Error:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to load point system configuration',
                error: error.message
            });
        }
    });



    // Reload point system configuration
    router.post('/point-system/reload', async(req, res) => {
        try {
            const pointCalculator = new PointCalculator();
            pointCalculator.reloadConfig();

            // Clear route cache to ensure fresh data
            routeCache.removeCache('/api/point-system');

            res.json({
                success: true,
                message: 'Point system configuration reloaded successfully',
                version: pointCalculator.getConfig().version,
                last_updated: pointCalculator.getConfig().last_updated
            });
        } catch (error) {
            console.error('[/api/point-system/reload] Error:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to reload point system configuration',
                error: error.message
            });
        }
    });

    // Point calculation breakdown for a specific session
    router.get('/point-breakdown/:sessionId', async(req, res) => {
        try {
            const sessionId = req.params.sessionId;

            // Get session data
            const [sessions] = await pool.execute(
                'SELECT * FROM stats_games WHERE id = ?',
                [sessionId]
            );

            if (sessions.length === 0) {
                return res.status(404).json({
                    success: false,
                    message: 'Session not found'
                });
            }

            const session = sessions[0];
            const pointCalculator = new PointCalculator();
            const breakdown = pointCalculator.calculateSessionPoints(session);
            const warnings = pointCalculator.validateSessionData(session);

            res.json({
                success: true,
                session_id: sessionId,
                steamid: session.steamid,
                breakdown: breakdown,
                warnings: warnings,
                session_data: session
            });
        } catch (error) {
            console.error('[/api/point-breakdown] Error:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to calculate point breakdown',
                error: error.message
            });
        }
    });

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
            // Get longest individual player playtime (Total Playtime = longest play time of any single player)
            const [longestPlaytime] = await pool.execute(`SELECT
            max(nullif(minutes_played,0)) * 60 as longest_playtime
            FROM stats_users`)

            // Get aggregated stats from stats_users table for more accurate totals
            const [totals] = await pool.execute(`SELECT
            sum(nullif(common_kills,0)) as zombie_kills,
            sum(nullif(survivor_ff,0)) as survivor_ff,
            sum(nullif(heal_others,0)) as MedkitsUsed,
            0 as FirstAidShared,
            sum(nullif(pills_used,0)) as PillsUsed,
            sum(nullif(adrenaline_used,0)) as AdrenalinesUsed,
            sum(nullif(throws_molotov,0)) as MolotovsUsed,
            sum(nullif(throws_pipe,0)) as PipebombsUsed,
            sum(nullif(throws_puke,0)) as BoomerBilesUsed,
            sum(nullif(survivor_damage_rec,0)) as DamageTaken,
            sum(nullif(melee_kills,0)) as MeleeKills,
            sum(nullif(revived_others,0)) as ReviveOtherCount,
            sum(nullif(defibs_used,0)) as DefibrillatorsUsed,
            sum(nullif(survivor_deaths,0)) as Deaths,
            sum(nullif(survivor_incaps,0)) as Incaps,
            sum(nullif(kills_boomer,0)) as boomer_kills,
            sum(nullif(kills_jockey,0)) as jockey_kills,
            sum(nullif(kills_smoker,0)) as smoker_kills,
            sum(nullif(kills_spitter,0)) as spitter_kills,
            sum(nullif(kills_hunter,0)) as hunter_kills,
            sum(nullif(kills_charger,0)) as charger_kills,
            (SELECT COUNT(*) FROM \`stats_games\`) AS total_sessions,
            (SELECT COUNT(distinct(campaignID)) from stats_games) AS total_games,
            (SELECT COUNT(*) FROM \`stats_users\`) AS total_users
            FROM stats_users`)

            // Combine longest playtime with other stats
            const combinedStats = {
                ...totals[0],
                game_duration: longestPlaytime[0]?.longest_playtime || 0
            }
            const [mapTotals] = await pool.execute("SELECT map,COUNT(*) as count FROM stats_games GROUP BY map ORDER BY COUNT(map) DESC")
            if(totals.length == 0) {
                return res.status(500).json({error:'Internal Server Error'})
            }else{
                let stats = {}, maps = {};
                for(const key in combinedStats) {
                    stats[key] = parseInt(combinedStats[key])
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

            // Get average session duration from stats_games (actual campaign session times)
            const [avgSessionDuration] = await pool.execute(`SELECT
            avg(CASE WHEN date_end > 0 AND date_start > 0 THEN date_end - date_start ELSE 0 END) as avg_session_duration
            FROM (
                SELECT campaignID, MAX(date_end) as date_end, MIN(date_start) as date_start
                FROM stats_games
                WHERE date_end > 0 AND date_start > 0
                GROUP BY campaignID
            ) as sessions`)

            // Get average stats from stats_users table for more accurate averages
            const [topStats] = await pool.execute(`SELECT
            avg(nullif(common_kills,0)) as zombie_kills,
            avg(nullif(survivor_ff,0)) as survivor_ff,
            avg(nullif(heal_others,0)) as MedkitsUsed,
            0 as FirstAidShared,
            avg(nullif(pills_used,0)) as PillsUsed,
            avg(nullif(adrenaline_used,0)) as AdrenalinesUsed,
            avg(nullif(throws_molotov,0)) as MolotovsUsed,
            avg(nullif(throws_pipe,0)) as PipebombsUsed,
            avg(nullif(throws_puke,0)) as BoomerBilesUsed,
            avg(nullif(survivor_damage_rec,0)) as DamageTaken,
            2 as difficulty,
            avg(nullif(melee_kills,0)) as MeleeKills,
            0 as ping,
            avg(nullif(revived_others,0)) as ReviveOtherCount,
            avg(nullif(defibs_used,0)) as DefibrillatorsUsed,
            avg(nullif(survivor_deaths,0)) as Deaths,
            avg(nullif(survivor_incaps,0)) as Incaps,
            avg(nullif(kills_boomer,0)) as boomer_kills,
            avg(nullif(kills_jockey,0)) as jockey_kills,
            avg(nullif(kills_smoker,0)) as smoker_kills,
            avg(nullif(kills_spitter,0)) as spitter_kills,
            avg(nullif(kills_hunter,0)) as hunter_kills,
            avg(nullif(kills_charger,0)) as charger_kills
            FROM stats_users`)
            let stats = {};
            if(topStats[0]) {
                for(const key in topStats[0]) {
                    if(key == "difficulty") {
                        stats[key] = Math.round(parseFloat(topStats[0][key]))
                    }else{
                        stats[key] = parseFloat(topStats[0][key])
                    }
                }
                // Add the correct session duration
                stats.game_duration = avgSessionDuration[0]?.avg_session_duration || 0;
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

    // Legacy endpoint - redirect to new point-system endpoint
    router.get('/point-rules', routeCache.cacheSeconds(300), async(req,res) => {
        try {
            const pointCalculator = new PointCalculator();
            const config = pointCalculator.getConfig();

            // Convert new format to legacy format for backward compatibility
            const legacyFormat = {
                point_values: {
                    positive_actions: {},
                    penalties: {}
                },
                calculation_rules: config.calculation_settings
            };

            // Convert base points to legacy format
            for (const [key, rule] of Object.entries(config.base_points.rules)) {
                if (rule.enabled !== false) {
                    const multiplier = rule.points_per_kill || rule.points_per_headshot ||
                                     rule.points_per_damage || rule.points_per_heal ||
                                     rule.points_per_revive || rule.points_per_defib ||
                                     rule.points_per_crown || rule.points_per_save ||
                                     rule.points_per_pack || rule.points || 1;
                    legacyFormat.point_values.positive_actions[key] = multiplier;
                }
            }

            // Convert penalties to legacy format
            for (const [key, rule] of Object.entries(config.penalties.rules)) {
                if (rule.enabled !== false) {
                    const multiplier = rule.points_per_damage || rule.points_per_kill || rule.points_per_death || 0;
                    legacyFormat.point_values.penalties[key] = multiplier;
                }
            }

            res.json({
                success: true,
                rules: legacyFormat,
                note: "This endpoint is deprecated. Use /api/point-system for the new format."
            });
        } catch(err) {
            console.error('[/api/point-rules]', err.message);
            res.status(500).json({
                success: false,
                error: 'Failed to load point calculation rules',
                message: err.message
            });
        }
    });

    // Recalculate all user points based on current rules
    router.post('/recalculate', async(req,res) => {
        try {
            console.log('[/api/recalculate] Starting point recalculation...');
            
            // Initialize point calculator with new system
            const pointCalculator = new PointCalculator();
            console.log('[/api/recalculate] Loaded point system configuration');
            
            // Clear existing points
            await pool.execute("DELETE FROM stats_points");
            console.log('[/api/recalculate] Cleared existing points');
            
            // Reset user points to 0
            await pool.execute("UPDATE stats_users SET points = 0");
            console.log('[/api/recalculate] Reset user points to 0');
            
            // Get all game sessions ordered by date
            const [sessions] = await pool.execute(`
                SELECT * FROM stats_games 
                WHERE date_end > 0 AND date_start > 0 
                ORDER BY date_end ASC
            `);
            
            console.log(`[/api/recalculate] Processing ${sessions.length} sessions...`);
            
            if (sessions.length === 0) {
                return res.json({
                    success: false,
                    message: 'No valid sessions found to process',
                    stats: { sessions_processed: 0 }
                });
            }
            
            let processedCount = 0;
            let totalPointsCalculated = 0;
            const batchSize = 100;

            for (let i = 0; i < sessions.length; i += batchSize) {
                const batch = sessions.slice(i, i + batchSize);

                for (const session of batch) {
                    // Calculate points using new point system
                    const pointBreakdown = pointCalculator.calculateSessionPoints(session);
                    let points = pointBreakdown.total;

                    // Validate session data
                    const warnings = pointCalculator.validateSessionData(session);
                    if (warnings.length > 0) {
                        console.warn(`Session ${session.id} validation warnings:`, warnings);
                    }

                    // Limit points range to prevent database overflow
                    points = Math.max(-50000, Math.min(50000, points));
                    
                    // Allow negative points but track total
                    totalPointsCalculated += points;
                    
                    if (Math.abs(points) > 0) { // Record both positive and negative points
                        // Insert point record (type should be an integer, not a string)
                        await pool.execute(
                            "INSERT INTO stats_points (steamid, timestamp, type, amount) VALUES (?, ?, ?, ?)",
                            [session.steamid, session.date_end, 0, points]
                        );
                        
                        // Update user total (allow negative points by removing GREATEST constraint)
                        await pool.execute(
                            "UPDATE stats_users SET points = points + ? WHERE steamid = ?",
                            [points, session.steamid]
                        );
                        
                        // Debug log for first few sessions
                        if (processedCount < 5) {
                            console.log(`[/api/recalculate] Session ${processedCount + 1}: ${session.steamid} earned ${points} points`);
                            console.log(`  - Zombies: ${session.ZombieKills || 0}, Specials: ${session.SpecialInfectedKills || 0}`);
                            console.log(`  - FF Damage: ${session.SurvivorDamage || 0}, Finale: ${session.finale_time > 0 ? 'Yes' : 'No'}`);
                        }
                    }
                    
                    processedCount++;
                }
                
                // Log progress every batch
                console.log(`[/api/recalculate] Processed ${Math.min(i + batchSize, sessions.length)}/${sessions.length} sessions`);
            }
            
            // Get final stats
            const [finalStats] = await pool.execute(`
                SELECT 
                    COUNT(*) as total_users,
                    SUM(points) as total_points,
                    AVG(points) as avg_points,
                    MAX(points) as max_points
                FROM stats_users 
                WHERE points > 0
            `);
            
            console.log('[/api/recalculate] Recalculation completed successfully');
            
            res.json({
                success: true,
                message: 'Points recalculated successfully',
                stats: {
                    sessions_processed: processedCount,
                    total_points_calculated: totalPointsCalculated,
                    ...finalStats[0]
                }
            });
            
        } catch(err) {
            console.error('[/api/recalculate]', err.message);
            res.status(500).json({
                success: false,
                error: 'Failed to recalculate points',
                message: err.message
            });
        }
    });

    return router;
}