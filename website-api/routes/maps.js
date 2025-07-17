import Router from 'express'
const router = Router()
import routeCache from 'route-cache'
import PointCalculator from '../services/PointCalculator.js'

export default function(pool) {
    router.get('/', routeCache.cacheSeconds(120), async (req, res) => {
        const [rows] = await pool.query(`
            SELECT i.mapid as map_id, i.name as map_name, AVG(r.value) as avg_rating, COUNT(DISTINCT r.steamid) as num_ratings, COUNT(DISTINCT g.campaignID) as games_played, AVG(g.duration) as avg_duration, MAX(g.date_end) as last_played_time
            FROM map_info i
            LEFT JOIN left4dead2.map_ratings r ON i.mapid = r.map_id
            LEFT JOIN left4dead2.stats_games g ON g.map = i.mapid
            GROUP BY i.mapid
            ORDER BY games_played DESC, avg_rating DESC
        `)

        return res.json(rows.map(row => {
            return {
                map: {
                    id: row.map_id,
                    name: row.map_name
                },
                avgRating: row.avg_rating,
                numRatings: row.num_ratings,
                gamesPlayed: row.games_played,
                avgDuration: row.avg_duration,
                lastPlayedTime: row.last_played_time
            }
        }))
    })

    router.get('/:map', routeCache.cacheSeconds(120), async (req, res) => {
        const [maps] = await pool.query("SELECT name, chapter_count FROM map_info WHERE mapid = ?", [req.params.map])
        if(maps.length == 0) {
            return res.status(404).json({
                error: "NO_MAP_FOUND",
                message: "Unknown map"
            })
        }
        const map = maps[0]
        const [rows] = await pool.query(
            "SELECT r.*, u.last_alias as user_name FROM map_ratings r JOIN stats_users u ON u.steamid = r.steamid WHERE map_id = ?",
            [req.params.map]
        )
        let sum = 0

        const ratings = rows.map(row => {
            sum += row.value
            return {
                user: {
                    id: row.steamid,
                    name: row.user_name
                },
                value: row.value,
                comment: row.comment
            }
        })

        return res.json({
            map: {
                id: req.params.map,
                name: map.name,
                chapters: map.chapter_count
            },
            avgRating: sum / rows.length,
            ratings
        })
    })

    // Calculate map-specific points for a user based on stats_map_users data
    router.get('/:mapid/users/:steamid/points/calculate', routeCache.cacheSeconds(120), async (req, res) => {
        try {
            const mapid = req.params.mapid;
            const steamid = req.params.steamid;
            const sessionStart = req.query.session_start; // Optional: specific session timestamp

            // Verify map exists
            const [maps] = await pool.execute(
                'SELECT name, chapter_count FROM map_info WHERE mapid = ?',
                [mapid]
            );

            if (maps.length === 0) {
                return res.status(404).json({
                    success: false,
                    message: 'Map not found'
                });
            }

            // Get map-specific user data from stats_map_users table
            let query, params;
            if (sessionStart) {
                // Get specific session
                query = 'SELECT * FROM stats_map_users WHERE steamid = ? AND mapid = ? AND session_start = ?';
                params = [steamid, mapid, sessionStart];
            } else {
                // Get most recent session for this user on this map
                query = 'SELECT * FROM stats_map_users WHERE steamid = ? AND mapid = ? ORDER BY session_start DESC LIMIT 1';
                params = [steamid, mapid];
            }

            const [mapUserData] = await pool.execute(query, params);

            if (mapUserData.length === 0) {
                return res.status(404).json({
                    success: false,
                    message: 'No session data found for this user on this map'
                });
            }

            const userData = mapUserData[0];
            const pointCalculator = new PointCalculator();
            const breakdown = pointCalculator.calculateMapPoints(userData);

            res.json({
                success: true,
                steamid: userData.steamid,
                mapid: userData.mapid,
                calculation_type: 'map_specific',
                breakdown: breakdown,
                map_data: {
                    steamid: userData.steamid,
                    mapid: userData.mapid,
                    map_name: maps[0].name,
                    last_alias: userData.last_alias,
                    points: userData.points,
                    session_start: userData.session_start,
                    session_end: userData.session_end
                }
            });
        } catch (error) {
            console.error('[/api/maps/:mapid/users/:steamid/points/calculate] Error:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to calculate map-specific points',
                error: error.message
            });
        }
    })

    // Calculate MVP points for map-specific user statistics
    router.get('/:mapid/users/:steamid/mvp/calculate', routeCache.cacheSeconds(120), async (req, res) => {
        try {
            const mapid = req.params.mapid;
            const steamid = req.params.steamid;
            const sessionStart = req.query.session_start; // Optional: specific session timestamp

            // Verify map exists
            const [maps] = await pool.execute(
                'SELECT name, chapter_count FROM map_info WHERE mapid = ?',
                [mapid]
            );

            if (maps.length === 0) {
                return res.status(404).json({
                    success: false,
                    message: 'Map not found'
                });
            }

            // Get map-specific user data from stats_map_users table
            let query, params;
            if (sessionStart) {
                // Get specific session
                query = 'SELECT * FROM stats_map_users WHERE steamid = ? AND mapid = ? AND session_start = ?';
                params = [steamid, mapid, sessionStart];
            } else {
                // Get most recent session for this user on this map
                query = 'SELECT * FROM stats_map_users WHERE steamid = ? AND mapid = ? ORDER BY session_start DESC LIMIT 1';
                params = [steamid, mapid];
            }

            const [mapUserData] = await pool.execute(query, params);

            if (mapUserData.length === 0) {
                return res.status(404).json({
                    success: false,
                    message: 'No session data found for this user on this map'
                });
            }

            const userData = mapUserData[0];
            const pointCalculator = new PointCalculator();
            const breakdown = pointCalculator.calculateMVPPoints(userData, 'map');

            res.json({
                success: true,
                steamid: userData.steamid,
                mapid: userData.mapid,
                calculation_type: 'mvp_map',
                breakdown: breakdown,
                map_data: {
                    steamid: userData.steamid,
                    mapid: userData.mapid,
                    map_name: maps[0].name,
                    last_alias: userData.last_alias,
                    points: userData.points,
                    session_start: userData.session_start,
                    session_end: userData.session_end
                }
            });
        } catch (error) {
            console.error('[/api/maps/:mapid/users/:steamid/mvp/calculate] Error:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to calculate map-specific MVP points',
                error: error.message
            });
        }
    })

    return router
}