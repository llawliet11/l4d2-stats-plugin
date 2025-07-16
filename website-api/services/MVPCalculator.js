/**
 * MVP Calculator Service
 * Provides consistent MVP calculation logic across all endpoints
 */

import fs from 'fs'
import path from 'path'

class MVPCalculator {
    constructor() {
        this.config = this.loadConfig()
    }

    /**
     * Load MVP calculation configuration
     */
    loadConfig() {
        try {
            const rulesPath = path.join(process.cwd(), 'config', 'calculation-rules.json')
            const rulesData = fs.readFileSync(rulesPath, 'utf8')
            const calculationRules = JSON.parse(rulesData)
            
            return {
                pointValues: calculationRules.point_values || {
                    positive_actions: {
                        common_kill: 1,
                        special_kill: 6,
                        tank_kill_max: 100,
                        witch_kill: 15,
                        heal_teammate: 40,
                        revive_teammate: 25,
                        defib_teammate: 30,
                        finale_win: 1000,
                        molotov_use: 5,
                        pipe_use: 5,
                        bile_use: 5,
                        pill_use: 10,
                        adrenaline_use: 15
                    },
                    penalties: {
                        teammate_kill: -100,
                        ff_damage_multiplier: -2
                    }
                },
                mvpCriteria: calculationRules.mvp_calculation?.criteria || [
                    { field: "SpecialInfectedKills", direction: "desc" },
                    { field: "SurvivorFFCount", direction: "asc" },
                    { field: "ZombieKills", direction: "desc" },
                    { field: "DamageTaken", direction: "asc" },
                    { field: "SurvivorDamage", direction: "asc" }
                ]
            }
        } catch (err) {
            console.warn('[MVPCalculator] Could not load calculation rules, using defaults:', err.message)
            return this.getDefaultConfig()
        }
    }

    /**
     * Get default configuration if config file is not available
     */
    getDefaultConfig() {
        return {
            pointValues: {
                positive_actions: {
                    common_kill: 1,
                    special_kill: 6,
                    tank_kill_max: 100,
                    witch_kill: 15,
                    heal_teammate: 40,
                    revive_teammate: 25,
                    defib_teammate: 30,
                    finale_win: 1000,
                    molotov_use: 5,
                    pipe_use: 5,
                    bile_use: 5,
                    pill_use: 10,
                    adrenaline_use: 15
                },
                penalties: {
                    teammate_kill: -100,
                    ff_damage_multiplier: -2
                }
            },
            mvpCriteria: [
                { field: "SpecialInfectedKills", direction: "desc" },
                { field: "SurvivorFFCount", direction: "asc" },
                { field: "ZombieKills", direction: "desc" },
                { field: "DamageTaken", direction: "asc" },
                { field: "SurvivorDamage", direction: "asc" }
            ]
        }
    }

    /**
     * Calculate MVP points for a single player
     * @param {Object} playerData - Player statistics object
     * @param {number} avgDamageTaken - Average damage taken by all players (for bonus calculation)
     * @returns {number} MVP points
     */
    calculateMVPPoints(playerData, avgDamageTaken = 0) {
        let mvpPoints = 0
        const pointValues = this.config.pointValues

        // Positive actions - use actual database column names
        mvpPoints += (playerData.special_infected_kills || 0) * pointValues.positive_actions.special_kill
        mvpPoints += (playerData.common_kills || 0) * pointValues.positive_actions.common_kill
        mvpPoints += (playerData.tanks_killed || 0) * pointValues.positive_actions.tank_kill_max
        mvpPoints += (playerData.kills_witch || 0) * pointValues.positive_actions.witch_kill
        mvpPoints += (playerData.heal_others || 0) * pointValues.positive_actions.heal_teammate
        mvpPoints += (playerData.revived_others || 0) * pointValues.positive_actions.revive_teammate
        mvpPoints += (playerData.defibs_used || 0) * pointValues.positive_actions.defib_teammate
        mvpPoints += (playerData.finales_won || 0) * pointValues.positive_actions.finale_win

        // Additional positive actions
        mvpPoints += (playerData.throws_molotov || 0) * pointValues.positive_actions.molotov_use
        mvpPoints += (playerData.throws_pipe || 0) * pointValues.positive_actions.pipe_use
        mvpPoints += (playerData.throws_puke || 0) * pointValues.positive_actions.bile_use
        mvpPoints += (playerData.pills_used || 0) * pointValues.positive_actions.pill_use
        mvpPoints += (playerData.adrenaline_used || 0) * pointValues.positive_actions.adrenaline_use

        // Penalties
        mvpPoints += (playerData.ff_kills || 0) * pointValues.penalties.teammate_kill
        mvpPoints += (playerData.survivor_ff || 0) * pointValues.penalties.ff_damage_multiplier

        // Damage taken bonus (reward for taking less damage than average)
        if (avgDamageTaken > 0) {
            const damageTakenBonus = Math.max(0, (avgDamageTaken - (playerData.survivor_damage_rec || 0)) * 0.5)
            mvpPoints += damageTakenBonus
        }

        return Math.round(mvpPoints)
    }

    /**
     * Calculate MVP for a list of players and mark the MVP
     * @param {Array} players - Array of player objects
     * @returns {Array} Players array with MVP points and isMVP flag
     */
    calculateAndMarkMVP(players) {
        if (!players || players.length === 0) {
            return players
        }

        // Calculate average damage taken for bonus calculation
        const totalDamageTaken = players.reduce((sum, player) => 
            sum + (player.DamageTaken || player.damage_taken || 0), 0)
        const avgDamageTaken = players.length > 0 ? totalDamageTaken / players.length : 0

        // Calculate MVP points for each player
        players.forEach(player => {
            player.mvpPoints = this.calculateMVPPoints(player, avgDamageTaken)

            // Add estimated survivor_ff_count for display if not present (for backward compatibility)
            if (!player.survivor_ff_count) {
                player.survivor_ff_count = Math.round((player.survivor_ff || 0) / 10)
            }
        })

        // Sort players by MVP points to determine MVP
        const sortedPlayers = [...players].sort((a, b) => (b.mvpPoints || 0) - (a.mvpPoints || 0))

        // Mark the MVP (highest MVP points)
        if (sortedPlayers.length > 0) {
            const mvpSteamId = sortedPlayers[0].steamid
            players.forEach(player => {
                player.isMVP = player.steamid === mvpSteamId
            })
        }

        return players
    }

    /**
     * Get MVP criteria for database ordering (fallback method)
     * @returns {string} SQL ORDER BY clause
     */
    getMVPOrderBy() {
        return this.config.mvpCriteria.map(c => `${c.field} ${c.direction}`).join(', ')
    }

    /**
     * Get point values configuration
     * @returns {Object} Point values configuration
     */
    getPointValues() {
        return this.config.pointValues
    }

    /**
     * Get MVP criteria configuration
     * @returns {Array} MVP criteria array
     */
    getMVPCriteria() {
        return this.config.mvpCriteria
    }
}

// Export singleton instance
export default new MVPCalculator()
