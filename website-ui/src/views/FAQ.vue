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

                        <!-- Dynamic Point Rules -->
                        <div v-if="!loadingRules">
                            <h6 class="title is-6 has-text-success">Positive Actions:</h6>
                            <ul>
                                <li v-for="(rule, key) in basePointRules" :key="key" v-if="rule.enabled !== false">
                                    <span class="has-text-success">
                                        +{{ rule.points_per_kill || rule.points_per_headshot || rule.points_per_damage || rule.points_per_heal || rule.points_per_revive || rule.points_per_defib || rule.points_per_crown || rule.points_per_save || rule.points_per_pack || rule.points_per_finale || rule.points || 0 }}
                                    </span>
                                    {{ rule.description }}
                                    <em v-if="rule.note"> ({{ rule.note }})</em>
                                </li>
                            </ul>

                            <br>
                            <h6 class="title is-6 has-text-danger">Penalties:</h6>
                            <ul>
                                <li v-for="(rule, key) in penaltyRules" :key="key" v-if="rule.enabled !== false">
                                    <span class="has-text-danger">
                                        {{ rule.points_per_damage || rule.points_per_kill || rule.points_per_death || 0 }}
                                    </span>
                                    {{ rule.description }}
                                    <em v-if="rule.note"> ({{ rule.note }})</em>
                                </li>
                            </ul>
                        </div>

                        <br>
                        <p><strong>Healing Anti-Abuse System:</strong> To prevent point farming, healing points are only awarded when:</p>
                        <ul>
                            <li>Target player has ≤60% health</li>
                            <li>5-minute cooldown has expired since last heal on same target</li>
                            <li>Critical heals (≤30% health) award bonus points (+60 instead of +40)</li>
                            <li>Cooldown persists through team wipes and map restarts</li>
                        </ul>

                      <br>
                      <p><strong>Tank Kill Points:</strong> When a tank is killed, the 100 points are distributed among all players who participated in the current game session based on their damage contribution. For example, if 4 players fight a tank and deal 50%, 30%, 15%, and 5% damage respectively, they receive 50, 30, 15, and 5 points. Solo and melee bonuses are awarded only to the player who delivers the killing blow.</p>
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
                            <li><strong>Special Infected Kills × {{ mvpPositiveActions.special_kill || 6 }}</strong> - Reward skilled gameplay</li>
                            <li><strong>Common Kills × {{ mvpPositiveActions.common_kill || 1 }}</strong> - Basic zombie clearing</li>
                            <li><strong>Tank Kills × {{ mvpPositiveActions.tank_kill_max || 100 }}</strong> - Major threat elimination</li>
                            <li><strong>Witch Kills × {{ mvpPositiveActions.witch_kill || 15 }}</strong> - Precision kills</li>
                            <li><strong>Heals × {{ mvpPositiveActions.heal_teammate || 40 }}</strong> - Team support</li>
                            <li><strong>Revives × {{ mvpPositiveActions.revive_teammate || 25 }}</strong> - Saving teammates</li>
                            <li><strong>Defibs × {{ mvpPositiveActions.defib_teammate || 30 }}</strong> - Critical rescues</li>
                            <li><strong>Finales Won × {{ mvpPositiveActions.finale_win || 1000 }}</strong> - Campaign completion</li>
                            <li><strong>Molotovs Used × {{ mvpPositiveActions.molotov_use || 5 }}</strong> - Tactical throwables</li>
                            <li><strong>Pipe Bombs Used × {{ mvpPositiveActions.pipe_use || 5 }}</strong> - Area control</li>
                            <li><strong>Bile Bombs Used × {{ mvpPositiveActions.bile_use || 5 }}</strong> - Distraction tactics</li>
                            <li><strong>Pills Used × {{ mvpPositiveActions.pill_use || 10 }}</strong> - Self-care</li>
                            <li><strong>Adrenaline Used × {{ mvpPositiveActions.adrenaline_use || 15 }}</strong> - Speed boost usage</li>
                            <li><strong>Damage Taken Bonus × {{ mvpPointValues.bonuses?.damage_taken_bonus_multiplier || 0.5 }}</strong> - Reward for taking less damage than average</li>
                        </ul>

                        <h6 class="title is-6 has-text-danger">Penalties:</h6>
                        <ul>
                            <li><strong>Teammate Kills × {{ mvpPenalties.teammate_kill || -100 }}</strong> - Severe penalty</li>
                            <li><strong>Friendly Fire Damage × {{ mvpPenalties.ff_damage_multiplier || -2 }}</strong> - Per damage point dealt to teammates</li>
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
    }
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
    }
  }
}
</script>
