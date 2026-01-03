import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Singleton instance
let instance = null;

class PointCalculator {
    constructor() {
        if (instance) {
            return instance;
        }

        this.config = null;
        this.configPath = path.join(__dirname, '../config/point-system.json');
        this.loadConfig();

        instance = this;
        return instance;
    }

    loadConfig() {
        try {
            const configData = fs.readFileSync(this.configPath, 'utf8');
            this.config = JSON.parse(configData);
            console.log(`Point system config loaded (version ${this.config.version})`);
        } catch (error) {
            console.error('Failed to load point system config:', error);
            throw new Error('Point system configuration not available');
        }
    }

    /**
     * Reload the configuration from file
     */
    reloadConfig() {
        console.log('Reloading point system configuration...');
        this.loadConfig();
        console.log('Point system configuration reloaded successfully');
    }



    /**
     * Calculate points for map-specific statistics
     * @param {Object} mapData - Raw data from stats_map_users
     * @returns {Object} - Detailed point breakdown
     */
    calculateMapPoints(mapData) {
        if (!this.config) {
            throw new Error('Point system not initialized');
        }

        const breakdown = {
            base_points: {},
            penalties: {},
            multipliers: {},
            special_bonuses: {},
            total: 0,
            details: [],
            data_source: 'stats_map_users'
        };

        // Calculate base points using map-specific data
        this.calculateBasePoints(mapData, breakdown);

        // Calculate penalties using map-specific data
        this.calculatePenalties(mapData, breakdown);

        // Apply multipliers (if enabled)
        this.applyMultipliers(mapData, breakdown);

        // Add special bonuses (if enabled)
        this.calculateSpecialBonuses(mapData, breakdown);

        // Calculate final total
        breakdown.total = this.calculateFinalTotal(breakdown);

        return breakdown;
    }

    /**
     * Calculate points for a single session/game
     * @param {Object} sessionData - Raw session data from stats_games
     * @returns {Object} - Detailed point breakdown
     */
    calculateSessionPoints(sessionData) {
        if (!this.config) {
            throw new Error('Point system not initialized');
        }

        const breakdown = {
            base_points: {},
            penalties: {},
            multipliers: {},
            special_bonuses: {},
            total: 0,
            details: []
        };

        // Calculate base points
        this.calculateBasePoints(sessionData, breakdown);
        
        // Calculate penalties
        this.calculatePenalties(sessionData, breakdown);
        
        // Apply multipliers (if enabled)
        this.applyMultipliers(sessionData, breakdown);
        
        // Add special bonuses (if enabled)
        this.calculateSpecialBonuses(sessionData, breakdown);
        
        // Calculate final total
        breakdown.total = this.calculateFinalTotal(breakdown);
        
        return breakdown;
    }

    /**
     * Calculate points for lifetime user statistics
     * @param {Object} userData - Raw data from stats_users
     * @returns {Object} - Detailed point breakdown
     */
    calculateUserPoints(userData) {
        if (!this.config) {
            throw new Error('Point system not initialized');
        }

        const breakdown = {
            base_points: {},
            penalties: {},
            multipliers: {},
            special_bonuses: {},
            total: 0,
            details: [],
            data_source: 'stats_users'
        };

        // Calculate base points using lifetime data
        this.calculateBasePoints(userData, breakdown);

        // Calculate penalties using lifetime data
        this.calculatePenalties(userData, breakdown);

        // Apply multipliers (if enabled)
        this.applyMultipliers(userData, breakdown);

        // Add special bonuses (if enabled)
        this.calculateSpecialBonuses(userData, breakdown);

        // Calculate final total
        breakdown.total = this.calculateFinalTotal(breakdown);

        return breakdown;
    }

    /**
     * Calculate MVP points using map-specific or lifetime data
     * @param {Object} userData - Raw data from stats_map_users or stats_users
     * @param {string} calculationType - 'map' or 'overall'
     * @returns {Object} - MVP point breakdown
     */
    calculateMVPPoints(userData, calculationType = 'overall') {
        if (!this.config || !this.config.mvp_calculation) {
            throw new Error('MVP calculation configuration not available');
        }

        const mvpConfig = this.config.mvp_calculation;
        const breakdown = {
            positive_actions: {},
            penalties: {},
            bonuses: {},
            total: 0,
            details: [],
            calculation_type: calculationType,
            data_source: calculationType === 'map' ? 'stats_map_users' : 'stats_users'
        };

        // Calculate positive actions
        if (mvpConfig.point_values && mvpConfig.point_values.positive_actions) {
            for (const [action, points] of Object.entries(mvpConfig.point_values.positive_actions)) {
                const value = userData[action] || 0;
                if (value > 0) {
                    breakdown.positive_actions[action] = {
                        value: value,
                        points: value * points,
                        description: `${action.replace(/_/g, ' ')}: ${value} × ${points}`
                    };
                }
            }
        }

        // Calculate penalties
        if (mvpConfig.point_values && mvpConfig.point_values.penalties) {
            for (const [penalty, multiplier] of Object.entries(mvpConfig.point_values.penalties)) {
                if (penalty === 'ff_damage_multiplier') {
                    const ffDamage = userData.survivor_ff || 0;
                    if (ffDamage > 0) {
                        const penaltyPoints = ffDamage * Math.abs(multiplier);
                        breakdown.penalties[penalty] = {
                            value: ffDamage,
                            penalty: penaltyPoints,
                            description: `Friendly fire damage: ${ffDamage} × ${Math.abs(multiplier)}`
                        };
                    }
                }
            }
        }

        // Calculate bonuses (if any)
        if (mvpConfig.point_values && mvpConfig.point_values.bonuses) {
            for (const [bonus, config] of Object.entries(mvpConfig.point_values.bonuses)) {
                if (bonus !== 'description') {
                    // Bonus calculation logic would go here
                    // This is placeholder for future bonus implementations
                }
            }
        }

        // Calculate final MVP total
        let total = 0;

        // Add positive actions
        for (const action of Object.values(breakdown.positive_actions)) {
            total += action.points;
        }

        // Subtract penalties
        for (const penalty of Object.values(breakdown.penalties)) {
            total -= penalty.penalty;
        }

        // Add bonuses
        for (const bonus of Object.values(breakdown.bonuses)) {
            total += bonus.points || 0;
        }

        breakdown.total = Math.max(0, total); // MVP points cannot be negative

        return breakdown;
    }

    calculateBasePoints(sessionData, breakdown) {
        const baseRules = this.config.base_points.rules;
        
        for (const [ruleName, rule] of Object.entries(baseRules)) {
            // Skip disabled rules
            if (rule.enabled === false) continue;
            
            let points = 0;
            let value = 0;

            if (rule.condition) {
                // Special condition-based rules (like finale completion)
                if (this.evaluateCondition(rule.condition, sessionData)) {
                    points = rule.points_per_finale || rule.points || 0;
                    value = 1;
                }
            } else if (rule.source_field) {
                // Field-based rules
                value = sessionData[rule.source_field] || 0;

                // Handle special calculations
                if (rule.calculation) {
                    points = this.calculateSpecialRule(rule, sessionData, value);
                } else {
                    // Standard multiplier calculation
                    const multiplier = rule.points_per_kill || rule.points_per_headshot ||
                                     rule.points_per_damage || rule.points_per_heal ||
                                     rule.points_per_revive || rule.points_per_defib ||
                                     rule.points_per_crown || rule.points_per_save ||
                                     rule.points_per_pack || 1;
                    points = value * multiplier;
                }
            }

            if (points > 0) {
                breakdown.base_points[ruleName] = {
                    value: value,
                    points: points,
                    description: rule.description
                };
                breakdown.details.push(`${rule.description}: ${value} × ${points/value} = +${points}`);
            }
        }
    }

    calculatePenalties(sessionData, breakdown) {
        const penaltyRules = this.config.penalties.rules;
        
        for (const [ruleName, rule] of Object.entries(penaltyRules)) {
            if (rule.enabled === false) continue;

            let penalty = 0;
            let value = 0;

            if (rule.source_field) {
                value = sessionData[rule.source_field] || 0;
                if (value > 0) {
                    const multiplier = rule.points_per_damage || rule.points_per_kill || rule.points_per_death || 0;
                    penalty = value * Math.abs(multiplier); // Always positive for penalty calculation
                }
            }

            if (penalty > 0) {
                breakdown.penalties[ruleName] = {
                    value: value,
                    penalty: penalty,
                    description: rule.description
                };
                breakdown.details.push(`${rule.description}: ${value} × ${Math.abs(rule.points_per_damage || rule.points_per_kill || rule.points_per_death)} = -${penalty}`);
            }
        }
    }

    applyMultipliers(sessionData, breakdown) {
        const multiplierRules = this.config.multipliers.rules;
        
        for (const [ruleName, rule] of Object.entries(multiplierRules)) {
            if (rule.enabled === false) continue;
            
            // Multiplier logic would go here when implemented
            // Currently all multipliers are disabled
        }
    }

    calculateSpecialBonuses(sessionData, breakdown) {
        const bonusRules = this.config.special_bonuses.rules;
        
        for (const [ruleName, rule] of Object.entries(bonusRules)) {
            if (rule.enabled === false) continue;
            
            if (rule.condition && this.evaluateCondition(rule.condition, sessionData)) {
                breakdown.special_bonuses[ruleName] = {
                    points: rule.points,
                    description: rule.description
                };
                breakdown.details.push(`${rule.description}: +${rule.points}`);
            }
        }
    }

    calculateFinalTotal(breakdown) {
        let total = 0;
        
        // Add base points
        for (const points of Object.values(breakdown.base_points)) {
            total += points.points;
        }
        
        // Subtract penalties
        for (const penalty of Object.values(breakdown.penalties)) {
            total -= penalty.penalty;
        }
        
        // Add special bonuses
        for (const bonus of Object.values(breakdown.special_bonuses)) {
            total += bonus.points;
        }
        
        // Apply rounding if specified
        if (this.config.calculation_settings.round_final_score) {
            total = Math.round(total);
        }
        
        return total;
    }

    calculateSpecialRule(rule, sessionData, value) {
        switch (rule.calculation) {
            case 'damage_percent * 100':
                // Tank damage calculation
                const tankHp = rule.tank_hp_estimate || 6000;
                const damagePercent = value / tankHp;
                return Math.floor(damagePercent * 100);

            case 'special_kills * save_ratio':
                // Teammate save calculation
                const saveRatio = rule.save_ratio || 0.3;
                return Math.floor(value * saveRatio);

            case 'heals * critical_ratio':
                // Critical heal calculation
                const criticalRatio = rule.critical_ratio || 0.2;
                return Math.floor(value * criticalRatio);

            default:
                console.warn(`Unknown calculation type: ${rule.calculation}`);
                return 0;
        }
    }

    evaluateCondition(condition, data) {
        try {
            // Simple condition evaluation - can be enhanced for complex conditions
            // Currently supports basic comparisons like "finale_time > 0"
            return eval(condition.replace(/(\w+)/g, (match) => {
                return data[match] !== undefined ? data[match] : 0;
            }));
        } catch (error) {
            console.warn(`Failed to evaluate condition: ${condition}`, error);
            return false;
        }
    }

    /**
     * Get point system configuration
     * @returns {Object} - Current configuration
     */
    getConfig() {
        return this.config;
    }

    /**
     * Reload configuration from file
     */
    reloadConfig() {
        this.loadConfig();
    }

    /**
     * Validate session data - disabled, no limits applied
     * @param {Object} sessionData - Session data to validate
     * @returns {Array} - Empty array (no validation)
     */
    validateSessionData(sessionData) {
        return []; // No validation, no limits
    }
}

export default PointCalculator;
