<template>
<div>
    <section class="hero is-dark">
        <div class="hero-body">
            <div class="container has-text-centered">
            <h1 class="title">
                Frequently Asked Questions
            </h1>
            </div>
        </div>
    </section>
    <br>
    <div class="container has-text-left">
        <div class="column">
            <h5 class="title is-5">What is this?</h5>
            <p>This is a page for my <a href="https://github.com/Jackzmc/l4d2-stats-plugin">l4d2 stats plugin</a>. View information on how to set it up on the github linked. The plugin records kills, deaths, damage, skills and more from various left 4 dead game sessions and are displayed neatly on this website. This website is home to my personal servers I host, some for friends and some are public (see 'public' tags). </p>
            <hr>
            <b-collapse :open="true" class="card" animation="slide">
                <div
                    slot="trigger"
                    slot-scope="props"
                    class="card-header"
                    role="button">
                    <p class="card-header-title">
                        How are points calculated?
                    </p>
                    <a class="card-header-icon">
                        <b-icon
                            :icon="props.open ? 'caret-up' :  'caret-down'">
                        </b-icon>
                    </a>
                </div>
                <div class="card-content">
                    <div class="content">
                        <div v-if="loadingRules" class="has-text-centered">
                            <b-loading :is-full-page="false" v-model="loadingRules"></b-loading>
                            <p>Loading point calculation rules...</p>
                        </div>
                        <div v-else-if="rulesError" class="notification is-warning">
                            <p><strong>Warning:</strong> Could not load current point rules from server. Displaying fallback values.</p>
                            <p><em>{{ rulesError }}</em></p>
                        </div>

                        <!-- Point System Info -->
                        <div v-if="!loadingRules" class="notification is-info is-light mb-4">
                            <p><strong>Point System Version:</strong> {{ systemVersion }}</p>
                            <p><strong>Last Updated:</strong> {{ lastUpdated }}</p>
                            <p class="help">Edit the point-system.json file directly on the server, then click the button below to reload the rules.</p>
                            <div class="buttons">
                                <b-button
                                    type="is-primary"
                                    @click="reloadPointSystem"
                                    :loading="reloading">
                                    <span>Reload Rules</span>
                                </b-button>
                            </div>
                        </div>

                        <!-- Comprehensive Point Rules Display -->
                        <div v-if="!loadingRules">
                            <!-- Combat Actions -->
                            <div class="box mb-4">
                                <h6 class="title is-6 has-text-success">
                                    <b-icon icon="sword" size="is-small"></b-icon>
                                    Combat Actions
                                </h6>
                                <div class="columns is-multiline">
                                    <div v-for="(rule, key) in combatRules" :key="key" class="column is-half">
                                        <div class="notification is-light is-success">
                                            <div class="level is-mobile">
                                                <div class="level-left">
                                                    <div class="level-item">
                                                        <div>
                                                            <p class="heading">{{ rule.description }}</p>
                                                            <p class="title is-6 has-text-success">
                                                                +{{ getPointValue(rule) }} {{ getPointUnit(rule) }}
                                                            </p>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                            <p v-if="rule.note" class="help">{{ rule.note }}</p>
                                            <p v-if="rule.calculation" class="help has-text-info">
                                                <strong>Formula:</strong> {{ getCalculationDescription(rule) }}
                                            </p>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Teamwork Actions -->
                            <div class="box mb-4">
                                <h6 class="title is-6 has-text-info">
                                    <b-icon icon="account-group" size="is-small"></b-icon>
                                    Teamwork & Support
                                </h6>
                                <div class="columns is-multiline">
                                    <div v-for="(rule, key) in teamworkRules" :key="key" class="column is-half">
                                        <div class="notification is-light is-info">
                                            <div class="level is-mobile">
                                                <div class="level-left">
                                                    <div class="level-item">
                                                        <div>
                                                            <p class="heading">{{ rule.description }}</p>
                                                            <p class="title is-6 has-text-info">
                                                                +{{ getPointValue(rule) }} {{ getPointUnit(rule) }}
                                                            </p>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                            <p v-if="rule.note" class="help">{{ rule.note }}</p>
                                            <p v-if="rule.calculation" class="help has-text-info">
                                                <strong>Formula:</strong> {{ getCalculationDescription(rule) }}
                                            </p>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Special Bonuses -->
                            <div class="box mb-4" v-if="specialBonusRules.length > 0">
                                <h6 class="title is-6 has-text-warning">
                                    <b-icon icon="star" size="is-small"></b-icon>
                                    Special Bonuses
                                </h6>
                                <div class="columns is-multiline">
                                    <div v-for="(rule, key) in specialBonusRules" :key="key" class="column is-half">
                                        <div class="notification is-light is-warning">
                                            <div class="level is-mobile">
                                                <div class="level-left">
                                                    <div class="level-item">
                                                        <div>
                                                            <p class="heading">{{ rule.description }}</p>
                                                            <p class="title is-6 has-text-warning">
                                                                +{{ getPointValue(rule) }} {{ getPointUnit(rule) }}
                                                            </p>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                            <p v-if="rule.note" class="help">{{ rule.note }}</p>
                                            <p v-if="rule.calculation" class="help has-text-info">
                                                <strong>Formula:</strong> {{ getCalculationDescription(rule) }}
                                            </p>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Penalties -->
                            <div class="box mb-4">
                                <h6 class="title is-6 has-text-danger">
                                    <b-icon icon="alert" size="is-small"></b-icon>
                                    Penalties
                                </h6>
                                <div class="columns is-multiline">
                                    <div v-for="(rule, key) in penaltyRules" :key="key" v-if="rule.enabled !== false" class="column is-half">
                                        <div class="notification is-light is-danger">
                                            <div class="level is-mobile">
                                                <div class="level-left">
                                                    <div class="level-item">
                                                        <div>
                                                            <p class="heading">{{ rule.description }}</p>
                                                            <p class="title is-6 has-text-danger">
                                                                {{ getPointValue(rule) }} {{ getPointUnit(rule) }}
                                                            </p>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                            <p v-if="rule.note" class="help">{{ rule.note }}</p>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Point Calculation Summary -->
                            <div class="box">
                                <h6 class="title is-6">
                                    <b-icon icon="calculator" size="is-small"></b-icon>
                                    Point Calculation Formula
                                </h6>
                                <div class="content">
                                    <p><strong>Your session points are calculated as:</strong></p>
                                    <div class="notification is-light">
                                        <p class="has-text-centered is-size-5">
                                            <strong>Total Points = Base Points - Penalties + Special Bonuses</strong>
                                        </p>
                                    </div>
                                    <p>Where:</p>
                                    <ul>
                                        <li><strong>Base Points:</strong> Sum of all positive actions (combat + teamwork)</li>
                                        <li><strong>Penalties:</strong> Deductions for negative actions (friendly fire, team kills)</li>
                                        <li><strong>Special Bonuses:</strong> Additional rewards for exceptional performance</li>
                                    </ul>
                                    <p v-if="calculationSettings.round_final_score" class="help">
                                        Final scores are rounded to {{ calculationSettings.decimal_places || 0 }} decimal places.
                                    </p>
                                </div>
                            </div>
                        </div>

                        <br>
                        <p><strong>Healing Anti-Abuse System:</strong> To prevent point farming, healing points are only awarded when:</p>
                        <ul>
                            <li>Target player has ≤60% health</li>
                            <li>5-minute cooldown has expired since last heal on same target</li>
                            <li>Critical heals (≤30% health) award bonus points (+60 instead of +40)</li>
                            <li>Cooldown persists through team wipes and map restarts</li>
                        </ul>


                    </div>
                </div>
            </b-collapse>
            <b-collapse :open="true" class="card" animation="slide">
                            <div
                    slot="trigger"
                    slot-scope="props"
                    class="card-header"
                    role="button">
                    <p class="card-header-title">
                        How is campaign MVP calculated?
                    </p>
                    <a class="card-header-icon">
                        <b-icon
                            :icon="props.open ? 'caret-up' :  'caret-down'">
                        </b-icon>
                    </a>
                </div>
                <div class="card-content">
                    <div class="content">
                        <p>MVP is determined by calculating total points using the following formula:</p>

                        <h6 class="title is-6 has-text-success">Positive Actions:</h6>
                        <ul>
                            <li v-for="(value, key) in mvpPositiveActions" :key="key">
                                <strong>{{ getMvpActionDescription(key) }} × {{ value }}</strong> - {{ getMvpActionNote(key) }}
                            </li>
                        </ul>

                        <!-- MVP Bonuses Section -->
                        <div v-if="mvpPointValues.bonuses && Object.keys(mvpPointValues.bonuses).length > 0">
                            <h6 class="title is-6 has-text-warning">Bonuses:</h6>
                            <ul>
                                <li v-for="(value, key) in mvpPointValues.bonuses" :key="key" v-if="key !== 'description'">
                                    <strong>{{ getMvpBonusDescription(key) }} × {{ value }}</strong> - {{ mvpPointValues.bonuses.description || 'Special bonus calculation' }}
                                </li>
                            </ul>
                        </div>

                        <h6 class="title is-6 has-text-danger">Penalties:</h6>
                        <ul>
                            <li v-for="(value, key) in mvpPenalties" :key="key">
                                <strong>{{ getMvpPenaltyDescription(key) }} × {{ value }}</strong> - {{ getMvpPenaltyNote(key) }}
                            </li>
                        </ul>

                        <p><strong>The player with the highest MVP Points total is awarded MVP.</strong> This system rewards good teamwork, skilled gameplay, and penalizes excessive friendly fire.</p>
                    </div>
                </div>
            </b-collapse>


        </div>
    </div>
    <br>
</div>
</template>
<script>
export default {
  data() {
    return {
      pointSystem: null,
      loadingRules: true,
      rulesError: null,
      reloading: false
    }
  },
  async mounted() {
    await this.loadPointSystem()
  },

  computed: {
    basePointRules() {
      return this.pointSystem?.base_points?.rules || {}
    },
    penaltyRules() {
      return this.pointSystem?.penalties?.rules || {}
    },
    mvpPointValues() {
      return this.pointSystem?.mvp_calculation?.point_values || {}
    },
    mvpPositiveActions() {
      return this.mvpPointValues?.positive_actions || {}
    },
    mvpPenalties() {
      return this.mvpPointValues?.penalties || {}
    },
    systemVersion() {
      return this.pointSystem?.version || 'Unknown'
    },
    lastUpdated() {
      return this.pointSystem?.last_updated || 'Unknown'
    },
    calculationSettings() {
      return this.pointSystem?.calculation_settings || {}
    },

    // Categorized rules for better organization
    combatRules() {
      const rules = this.basePointRules
      const combatKeys = [
        'common_kills', 'common_headshots', 'special_infected_kills',
        'witch_kills', 'witch_crowns', 'tank_kill_max', 'tank_kill_solo',
        'tank_kill_melee', 'tank_damage'
      ]
      return this.filterRulesByKeys(rules, combatKeys)
    },

    teamworkRules() {
      const rules = this.basePointRules
      const teamworkKeys = [
        'first_aid_shared', 'first_aid_critical', 'revive_others',
        'defib_others', 'teammate_saves', 'finale_completion',
        'molotov_use', 'pipe_bomb_use', 'bile_bomb_use',
        'pills_used', 'adrenaline_used'
      ]
      return this.filterRulesByKeys(rules, teamworkKeys)
    },

    specialBonusRules() {
      const rules = this.basePointRules
      const specialKeys = [
        'finale_completion', 'perfect_round', 'no_damage_taken'
      ]
      return this.filterRulesByKeys(rules, specialKeys).filter(rule =>
        rule.condition || rule.calculation === 'special'
      )
    }
  },

  methods: {
    async loadPointSystem() {
      try {
        this.loadingRules = true
        const response = await this.$http.get('/api/point-system')

        if (response.data.success) {
          this.pointSystem = response.data.config
        } else {
          throw new Error(response.data.message || 'Failed to load point system')
        }
      } catch (error) {
        console.error('Failed to load point system:', error)
        this.rulesError = error.message
        // Fallback to default values if API fails
        this.pointSystem = {
          version: "fallback",
          base_points: {
            rules: {
              common_kills: { points_per_kill: 1, description: "Points per common infected kill" },
              special_infected_kills: { points_per_kill: 6, description: "Points per special infected kill" },
              witch_kills: { points_per_kill: 15, description: "Points for killing witch" },
              tank_kill_max: { points: 100, description: "Maximum points for tank kill contribution" },
              first_aid_shared: { points_per_heal: 40, description: "Points for healing teammates" },
              revive_others: { points_per_revive: 25, description: "Points for reviving teammates" },
              finale_completion: { points_per_finale: 1000, description: "Bonus points for completing finale" }
            }
          },
          penalties: {
            rules: {
              friendly_fire_damage: { points_per_damage: -40, description: "Penalty per HP damage dealt to teammates" },
              teammate_kills: { points_per_kill: -500, description: "Heavy penalty for killing teammates" }
            }
          }
        }
      } finally {
        this.loadingRules = false
      }
    },

    async reloadPointSystem() {
      try {
        this.reloading = true
        const response = await this.$http.post('/api/point-system/reload')

        if (response.data.success) {
          await this.loadPointSystem()
          this.$buefy.toast.open({
            message: 'Point system reloaded successfully!',
            type: 'is-success',
            duration: 3000
          })
        } else {
          throw new Error(response.data.message || 'Failed to reload point system')
        }
      } catch (error) {
        console.error('Failed to reload point system:', error)
        this.$buefy.toast.open({
          message: `Failed to reload: ${error.message}`,
          type: 'is-danger',
          duration: 5000
        })
      } finally {
        this.reloading = false
      }
    },

    // Helper methods for displaying point rules
    filterRulesByKeys(rules, keys) {
      return keys.map(key => rules[key]).filter(rule =>
        rule && rule.enabled !== false
      )
    },

    getPointValue(rule) {
      return rule.points_per_kill || rule.points_per_headshot ||
             rule.points_per_damage || rule.points_per_heal ||
             rule.points_per_revive || rule.points_per_defib ||
             rule.points_per_crown || rule.points_per_save ||
             rule.points_per_pack || rule.points_per_finale ||
             rule.points || 0
    },

    getPointUnit(rule) {
      if (rule.points_per_kill) return 'per kill'
      if (rule.points_per_headshot) return 'per headshot'
      if (rule.points_per_damage) return 'per damage'
      if (rule.points_per_heal) return 'per heal'
      if (rule.points_per_revive) return 'per revive'
      if (rule.points_per_defib) return 'per defib'
      if (rule.points_per_crown) return 'per crown'
      if (rule.points_per_save) return 'per save'
      if (rule.points_per_pack) return 'per pack'
      if (rule.points_per_finale) return 'per finale'
      return 'points'
    },

    getCalculationDescription(rule) {
      if (rule.calculation === 'tank_damage') {
        return 'Tank Damage ÷ 6000 × 100 (max 100 points)'
      }
      if (rule.calculation === 'teammate_saves') {
        return 'Special Kills × 0.3 × 10'
      }
      if (rule.calculation === 'special') {
        return rule.formula || 'Special calculation applied'
      }
      return rule.calculation || 'Standard calculation'
    },

    // Helper methods for MVP section
    getMvpActionDescription(key) {
      const descriptions = {
        'common_kill': 'Common Kills',
        'special_kill': 'Special Infected Kills',
        'tank_kill_max': 'Tank Kills',
        'witch_kill': 'Witch Kills',
        'heal_teammate': 'Heals',
        'revive_teammate': 'Revives',
        'defib_teammate': 'Defibs',
        'finale_win': 'Finales Won',
        'molotov_use': 'Molotovs Used',
        'pipe_use': 'Pipe Bombs Used',
        'bile_use': 'Bile Bombs Used',
        'pill_use': 'Pills Used',
        'adrenaline_use': 'Adrenaline Used'
      }
      return descriptions[key] || key.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
    },

    getMvpActionNote(key) {
      const notes = {
        'common_kill': 'Basic zombie clearing',
        'special_kill': 'Reward skilled gameplay',
        'tank_kill_max': 'Major threat elimination',
        'witch_kill': 'Precision kills',
        'heal_teammate': 'Team support',
        'revive_teammate': 'Saving teammates',
        'defib_teammate': 'Critical rescues',
        'finale_win': 'Campaign completion',
        'molotov_use': 'Tactical throwables',
        'pipe_use': 'Area control',
        'bile_use': 'Distraction tactics',
        'pill_use': 'Self-care',
        'adrenaline_use': 'Speed boost usage'
      }
      return notes[key] || 'Positive action points'
    },

    getMvpBonusDescription(key) {
      const descriptions = {
        'damage_taken_bonus_multiplier': 'Damage Taken Bonus'
      }
      return descriptions[key] || key.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
    },

    getMvpPenaltyDescription(key) {
      const descriptions = {
        'teammate_kill': 'Teammate Kills',
        'ff_damage_multiplier': 'Friendly Fire Damage'
      }
      return descriptions[key] || key.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
    },

    getMvpPenaltyNote(key) {
      const notes = {
        'teammate_kill': 'Severe penalty',
        'ff_damage_multiplier': 'Per damage point dealt to teammates'
      }
      return notes[key] || 'Penalty points'
    }
  }
}
</script>
