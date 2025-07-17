import pool from '../config/database.js';

/**
 * Data validation service for L4D2 stats plugin
 * Ensures consistency between stats_users and stats_map_users tables
 */
class DataValidator {
    constructor() {
        this.statisticalFields = [
            'common_kills',
            'kills_all_specials',
            'survivor_ff',
            'survivor_ff_rec',
            'heal_others',
            'revived_others',
            'defibs_used',
            'damage_to_tank',
            'kills_witch',
            'witches_crowned',
            'finales_won',
            'minutes_played',
            'survivor_deaths',
            'tanks_killed',
            'tanks_killed_solo',
            'tanks_killed_melee'
        ];
    }

    /**
     * Validate data consistency for a specific user
     * @param {string} steamid - User's Steam ID
     * @returns {Object} - Validation results
     */
    async validateUserConsistency(steamid) {
        try {
            const [userStats] = await pool.query(
                'SELECT * FROM stats_users WHERE steamid = ?',
                [steamid]
            );

            if (userStats.length === 0) {
                return {
                    valid: false,
                    error: 'User not found in stats_users table'
                };
            }

            const [mapStats] = await pool.query(
                'SELECT * FROM stats_map_users WHERE steamid = ?',
                [steamid]
            );

            const user = userStats[0];
            const validation = {
                steamid: steamid,
                valid: true,
                discrepancies: [],
                summary: {
                    total_map_sessions: mapStats.length,
                    fields_checked: this.statisticalFields.length,
                    fields_with_discrepancies: 0
                }
            };

            // Calculate totals from map sessions
            const mapTotals = {};
            for (const field of this.statisticalFields) {
                mapTotals[field] = mapStats.reduce((sum, session) => {
                    return sum + (parseInt(session[field]) || 0);
                }, 0);
            }

            // Compare with user totals
            for (const field of this.statisticalFields) {
                const userValue = parseInt(user[field]) || 0;
                const mapTotal = mapTotals[field] || 0;
                
                if (userValue !== mapTotal) {
                    validation.valid = false;
                    validation.discrepancies.push({
                        field: field,
                        user_total: userValue,
                        map_sessions_total: mapTotal,
                        difference: userValue - mapTotal,
                        percentage_diff: userValue > 0 ? ((userValue - mapTotal) / userValue * 100).toFixed(2) : 'N/A'
                    });
                }
            }

            validation.summary.fields_with_discrepancies = validation.discrepancies.length;

            return validation;

        } catch (error) {
            console.error('Error validating user consistency:', error);
            return {
                valid: false,
                error: error.message
            };
        }
    }

    /**
     * Validate data consistency for all users (batch validation)
     * @param {number} limit - Maximum number of users to check
     * @returns {Object} - Batch validation results
     */
    async validateAllUsersConsistency(limit = 100) {
        try {
            const [users] = await pool.query(
                'SELECT steamid FROM stats_users ORDER BY last_join_date DESC LIMIT ?',
                [limit]
            );

            const results = {
                total_users_checked: users.length,
                users_with_discrepancies: 0,
                total_discrepancies: 0,
                validation_results: []
            };

            for (const user of users) {
                const validation = await this.validateUserConsistency(user.steamid);
                
                if (!validation.valid && validation.discrepancies) {
                    results.users_with_discrepancies++;
                    results.total_discrepancies += validation.discrepancies.length;
                    results.validation_results.push(validation);
                }
            }

            return results;

        } catch (error) {
            console.error('Error in batch validation:', error);
            return {
                error: error.message
            };
        }
    }

    /**
     * Fix data inconsistencies by recalculating stats_users from stats_map_users
     * @param {string} steamid - User's Steam ID
     * @returns {Object} - Fix results
     */
    async fixUserConsistency(steamid) {
        const connection = await pool.getConnection();
        
        try {
            await connection.beginTransaction();

            // Get current user data
            const [userStats] = await connection.query(
                'SELECT * FROM stats_users WHERE steamid = ?',
                [steamid]
            );

            if (userStats.length === 0) {
                throw new Error('User not found in stats_users table');
            }

            // Calculate correct totals from map sessions
            const [mapStats] = await connection.query(
                'SELECT * FROM stats_map_users WHERE steamid = ?',
                [steamid]
            );

            const correctedTotals = {};
            for (const field of this.statisticalFields) {
                correctedTotals[field] = mapStats.reduce((sum, session) => {
                    return sum + (parseInt(session[field]) || 0);
                }, 0);
            }

            // Build UPDATE query
            const updateFields = this.statisticalFields.map(field => `${field} = ?`).join(', ');
            const updateValues = this.statisticalFields.map(field => correctedTotals[field]);
            updateValues.push(steamid);

            await connection.query(
                `UPDATE stats_users SET ${updateFields} WHERE steamid = ?`,
                updateValues
            );

            await connection.commit();

            return {
                success: true,
                steamid: steamid,
                fields_updated: this.statisticalFields.length,
                corrected_totals: correctedTotals
            };

        } catch (error) {
            await connection.rollback();
            console.error('Error fixing user consistency:', error);
            return {
                success: false,
                error: error.message
            };
        } finally {
            connection.release();
        }
    }

    /**
     * Check for orphaned records and invalid references
     * @returns {Object} - Orphaned data report
     */
    async checkOrphanedData() {
        try {
            // Check for stats_map_users records without corresponding stats_users
            const [orphanedMapUsers] = await pool.query(`
                SELECT smu.steamid, COUNT(*) as session_count
                FROM stats_map_users smu
                LEFT JOIN stats_users su ON smu.steamid = su.steamid
                WHERE su.steamid IS NULL
                GROUP BY smu.steamid
            `);

            // Check for stats_map_users records with invalid mapid
            const [invalidMapIds] = await pool.query(`
                SELECT smu.mapid, COUNT(*) as session_count
                FROM stats_map_users smu
                LEFT JOIN map_info mi ON smu.mapid = mi.mapid
                WHERE mi.mapid IS NULL
                GROUP BY smu.mapid
            `);

            return {
                orphaned_map_users: orphanedMapUsers,
                invalid_map_ids: invalidMapIds,
                total_orphaned_sessions: orphanedMapUsers.reduce((sum, item) => sum + item.session_count, 0),
                total_invalid_map_sessions: invalidMapIds.reduce((sum, item) => sum + item.session_count, 0)
            };

        } catch (error) {
            console.error('Error checking orphaned data:', error);
            return {
                error: error.message
            };
        }
    }

    /**
     * Generate a comprehensive data health report
     * @returns {Object} - Complete data health report
     */
    async generateHealthReport() {
        try {
            const [userCount] = await pool.query('SELECT COUNT(*) as count FROM stats_users');
            const [mapUserCount] = await pool.query('SELECT COUNT(*) as count FROM stats_map_users');
            const [mapCount] = await pool.query('SELECT COUNT(*) as count FROM map_info');

            const orphanedData = await this.checkOrphanedData();
            const sampleValidation = await this.validateAllUsersConsistency(50);

            return {
                timestamp: new Date().toISOString(),
                table_counts: {
                    stats_users: userCount[0].count,
                    stats_map_users: mapUserCount[0].count,
                    map_info: mapCount[0].count
                },
                data_integrity: {
                    orphaned_data: orphanedData,
                    sample_validation: sampleValidation
                },
                recommendations: this.generateRecommendations(orphanedData, sampleValidation)
            };

        } catch (error) {
            console.error('Error generating health report:', error);
            return {
                error: error.message
            };
        }
    }

    /**
     * Generate recommendations based on validation results
     * @param {Object} orphanedData - Orphaned data check results
     * @param {Object} sampleValidation - Sample validation results
     * @returns {Array} - Array of recommendations
     */
    generateRecommendations(orphanedData, sampleValidation) {
        const recommendations = [];

        if (orphanedData.total_orphaned_sessions > 0) {
            recommendations.push({
                priority: 'HIGH',
                issue: 'Orphaned map sessions found',
                description: `${orphanedData.total_orphaned_sessions} map sessions exist without corresponding user records`,
                action: 'Run cleanup script to remove orphaned records or create missing user records'
            });
        }

        if (orphanedData.total_invalid_map_sessions > 0) {
            recommendations.push({
                priority: 'MEDIUM',
                issue: 'Invalid map references found',
                description: `${orphanedData.total_invalid_map_sessions} map sessions reference non-existent maps`,
                action: 'Update map_info table or clean up invalid references'
            });
        }

        if (sampleValidation.users_with_discrepancies > 0) {
            recommendations.push({
                priority: 'MEDIUM',
                issue: 'Data consistency issues detected',
                description: `${sampleValidation.users_with_discrepancies} users have discrepancies between lifetime and map totals`,
                action: 'Run data consistency fix for affected users'
            });
        }

        if (recommendations.length === 0) {
            recommendations.push({
                priority: 'INFO',
                issue: 'No issues detected',
                description: 'Data integrity checks passed successfully',
                action: 'Continue regular monitoring'
            });
        }

        return recommendations;
    }
}

export default DataValidator;
