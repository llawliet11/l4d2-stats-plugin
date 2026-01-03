import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Service for updating point transaction amounts based on point-system.json rules
 */
class PointTransactionUpdater {
    constructor(pool) {
        this.pool = pool;
        this.pointSystem = null;
        this.typeToRuleMap = new Map();
        this.loadPointSystem();
    }

    /**
     * Load point-system.json configuration
     */
    loadPointSystem() {
        try {
            const configPath = path.join(__dirname, '../config/point-system.json');
            const configData = fs.readFileSync(configPath, 'utf8');
            this.pointSystem = JSON.parse(configData);
            this.buildTypeToRuleMap();
            console.log('[PointTransactionUpdater] Point system configuration loaded');
        } catch (error) {
            console.error('[PointTransactionUpdater] Failed to load point system:', error);
            throw error;
        }
    }

    /**
     * Build mapping from type number to rule configuration
     */
    buildTypeToRuleMap() {
        this.typeToRuleMap.clear();

        // Map base_points rules
        if (this.pointSystem.base_points && this.pointSystem.base_points.rules) {
            for (const [ruleName, rule] of Object.entries(this.pointSystem.base_points.rules)) {
                if (rule.type !== undefined && rule.type !== null) {
                    this.typeToRuleMap.set(rule.type, {
                        ...rule,
                        ruleName,
                        category: 'base_points'
                    });
                }
            }
        }

        // Map penalties rules
        if (this.pointSystem.penalties && this.pointSystem.penalties.rules) {
            for (const [ruleName, rule] of Object.entries(this.pointSystem.penalties.rules)) {
                if (rule.type !== undefined && rule.type !== null) {
                    this.typeToRuleMap.set(rule.type, {
                        ...rule,
                        ruleName,
                        category: 'penalties'
                    });
                }
            }
        }

        console.log(`[PointTransactionUpdater] Built type mapping for ${this.typeToRuleMap.size} point types`);
    }

    /**
     * Calculate correct point amount for a transaction based on its type
     */
    calculatePointsByType(type, transaction = {}) {
        const rule = this.typeToRuleMap.get(type);
        
        if (!rule) {
            console.warn(`[PointTransactionUpdater] No rule found for type ${type}`);
            return 0;
        }

        if (rule.enabled === false) {
            console.log(`[PointTransactionUpdater] Rule ${rule.ruleName} is disabled, returning 0 points`);
            return 0;
        }

        // Calculate points based on rule configuration
        let points = 0;

        // Handle different point calculation patterns
        if (rule.points_per_kill !== undefined) {
            points = rule.points_per_kill;
        } else if (rule.points_per_headshot !== undefined) {
            points = rule.points_per_headshot;
        } else if (rule.points_per_damage !== undefined) {
            points = rule.points_per_damage;
        } else if (rule.points_per_heal !== undefined) {
            points = rule.points_per_heal;
        } else if (rule.points_per_revive !== undefined) {
            points = rule.points_per_revive;
        } else if (rule.points_per_defib !== undefined) {
            points = rule.points_per_defib;
        } else if (rule.points_per_crown !== undefined) {
            points = rule.points_per_crown;
        } else if (rule.points_per_save !== undefined) {
            points = rule.points_per_save;
        } else if (rule.points_per_pack !== undefined) {
            points = rule.points_per_pack;
        } else if (rule.points_per_use !== undefined) {
            points = rule.points_per_use;
        } else if (rule.points_per_clear !== undefined) {
            points = rule.points_per_clear;
        } else if (rule.points_per_deadstop !== undefined) {
            points = rule.points_per_deadstop;
        } else if (rule.points_per_hit !== undefined) {
            points = rule.points_per_hit;
        } else if (rule.points_per_death !== undefined) {
            points = rule.points_per_death;
        } else if (rule.points_per_alarm !== undefined) {
            points = rule.points_per_alarm;
        } else if (rule.points_per_pin !== undefined) {
            points = rule.points_per_pin;
        } else if (rule.points_per_honk !== undefined) {
            points = rule.points_per_honk;
        } else if (rule.points_per_bile !== undefined) {
            points = rule.points_per_bile;
        } else if (rule.points_per_finale !== undefined) {
            points = rule.points_per_finale;
        } else if (rule.points !== undefined) {
            points = rule.points;
        } else {
            console.warn(`[PointTransactionUpdater] No point calculation method found for rule ${rule.ruleName}`);
            return 0;
        }

        return Math.round(points);
    }

    /**
     * Update point transaction amounts for all or specific users
     */
    async updatePointTransactions(options = {}) {
        const {
            userFilter = null,
            backupOriginal = true,
            dryRun = false,
            batchSize = 1000,
            forceVersionUpdate = true
        } = options;

        console.log('[PointTransactionUpdater] Starting point transaction update...');
        console.log(`[PointTransactionUpdater] Options:`, { userFilter, backupOriginal, dryRun, batchSize, forceVersionUpdate });

        const stats = {
            total_transactions: 0,
            updated_transactions: 0,
            unchanged_transactions: 0,
            version_updated_transactions: 0,
            errors: 0,
            backup_created: false
        };

        try {
            // Step 1: Backup original amounts if requested
            if (backupOriginal && !dryRun) {
                await this.backupOriginalAmounts(userFilter);
                stats.backup_created = true;
            }

            // Step 2: Get total count for progress tracking
            const countQuery = `
                SELECT COUNT(*) as total 
                FROM stats_points 
                ${userFilter ? 'WHERE steamid = ?' : ''}
            `;
            const [countResult] = await this.pool.execute(countQuery, userFilter ? [userFilter] : []);
            stats.total_transactions = countResult[0].total;

            console.log(`[PointTransactionUpdater] Processing ${stats.total_transactions} transactions...`);

            // Step 3: Process transactions in batches
            let offset = 0;
            let processedCount = 0;

            while (offset < stats.total_transactions) {
                const batchQuery = `
                    SELECT id, type, amount, steamid, timestamp, mapId
                    FROM stats_points 
                    ${userFilter ? 'WHERE steamid = ?' : ''}
                    ORDER BY id
                    LIMIT ? OFFSET ?
                `;
                
                const params = userFilter ? [userFilter, batchSize, offset] : [batchSize, offset];
                const [transactions] = await this.pool.execute(batchQuery, params);

                // Process each transaction in the batch
                for (const transaction of transactions) {
                    try {
                        const newAmount = this.calculatePointsByType(transaction.type, transaction);

                        if (newAmount !== transaction.amount) {
                            if (!dryRun) {
                                await this.pool.execute(`
                                    UPDATE stats_points
                                    SET amount = ?,
                                        calculated_at = NOW(),
                                        calculation_version = ?
                                    WHERE id = ?
                                `, [newAmount, this.pointSystem.version, transaction.id]);
                            }
                            stats.updated_transactions++;
                        } else {
                            // Force update calculation_version even if amount unchanged for consistency
                            if (forceVersionUpdate && !dryRun) {
                                await this.pool.execute(`
                                    UPDATE stats_points
                                    SET calculated_at = NOW(),
                                        calculation_version = ?
                                    WHERE id = ?
                                `, [this.pointSystem.version, transaction.id]);
                                stats.version_updated_transactions++;
                            }
                            stats.unchanged_transactions++;
                        }
                    } catch (error) {
                        console.error(`[PointTransactionUpdater] Error processing transaction ${transaction.id}:`, error);
                        stats.errors++;
                    }
                }

                processedCount += transactions.length;
                offset += batchSize;

                // Progress logging
                if (processedCount % 5000 === 0 || processedCount === stats.total_transactions) {
                    console.log(`[PointTransactionUpdater] Progress: ${processedCount}/${stats.total_transactions} transactions processed`);
                }
            }

            console.log('[PointTransactionUpdater] Point transaction update completed');
            return { success: true, stats };

        } catch (error) {
            console.error('[PointTransactionUpdater] Error during update:', error);
            return { success: false, error: error.message, stats };
        }
    }

    /**
     * Backup original amounts before updating
     */
    async backupOriginalAmounts(userFilter = null) {
        console.log('[PointTransactionUpdater] Creating backup of original amounts...');
        
        // Add backup columns if they don't exist
        try {
            await this.pool.execute(`
                ALTER TABLE stats_points 
                ADD COLUMN IF NOT EXISTS original_amount SMALLINT(6) DEFAULT NULL,
                ADD COLUMN IF NOT EXISTS calculated_at TIMESTAMP NULL,
                ADD COLUMN IF NOT EXISTS calculation_version VARCHAR(10) DEFAULT NULL
            `);
        } catch (error) {
            // Columns might already exist, that's okay
            console.log('[PointTransactionUpdater] Backup columns already exist or error adding them:', error.message);
        }

        // Backup original amounts where not already backed up
        const backupQuery = `
            UPDATE stats_points 
            SET original_amount = amount 
            WHERE original_amount IS NULL
            ${userFilter ? 'AND steamid = ?' : ''}
        `;
        
        const [result] = await this.pool.execute(backupQuery, userFilter ? [userFilter] : []);
        console.log(`[PointTransactionUpdater] Backed up ${result.affectedRows} original amounts`);
    }

    /**
     * Get statistics about point transactions
     */
    async getTransactionStats(userFilter = null) {
        const query = `
            SELECT 
                COUNT(*) as total_transactions,
                COUNT(DISTINCT type) as unique_types,
                COUNT(CASE WHEN original_amount IS NOT NULL THEN 1 END) as backed_up_transactions,
                COUNT(CASE WHEN calculated_at IS NOT NULL THEN 1 END) as recalculated_transactions,
                SUM(amount) as total_points,
                AVG(amount) as avg_points,
                MIN(amount) as min_points,
                MAX(amount) as max_points
            FROM stats_points
            ${userFilter ? 'WHERE steamid = ?' : ''}
        `;
        
        const [result] = await this.pool.execute(query, userFilter ? [userFilter] : []);
        return result[0];
    }
}

export default PointTransactionUpdater;
