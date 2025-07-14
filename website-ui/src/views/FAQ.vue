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
                        <ul v-if="!loadingRules">
                            <li><span class="has-text-success">+{{ positiveActions.common_kill || 1 }}</span> per common killed (any damage type)</li>
                            <li><span class="has-text-success">+{{ positiveActions.headshot || 2 }}</span> per common headshot</li>
                            <li><span class="has-text-success">+{{ positiveActions.special_kill || 6 }}</span> per special kill</li>
                            <li><span class="has-text-success">+{{ positiveActions.tank_kill_max || 100 }}</span> per tank kill <em>(total points distributed among all players in the session based on damage dealt)</em></li>
                            <li><span class="has-text-success">+{{ positiveActions.tank_kill_solo || 20 }}</span> per tank kill solo <em>(bonus for killer only)</em></li>
                            <li><span class="has-text-success">+{{ positiveActions.tank_kill_melee || 50 }}</span> per tank kill melee <em>(bonus for killer only)</em></li>
                            <li><span class="has-text-success">+{{ positiveActions.witch_kill || 15 }}</span> per witch kill</li>
                            <li><span class="has-text-success">+{{ positiveActions.heal_teammate || 40 }}</span> per heal teammate <em>(+{{ positiveActions.heal_teammate_critical || 60 }} if target ≤30% health)</em></li>
                            <li><span class="has-text-success">+{{ positiveActions.revive_teammate || 25 }}</span> per revive teammate</li>
                            <li><span class="has-text-success">+{{ positiveActions.defib_teammate || 50 }}</span> per teammate defibbed</li>
                            <li><span class="has-text-success">+{{ positiveActions.teammate_save || 20 }}</span> per teammate save from specials</li>
                            <li><span class="has-text-success">+{{ positiveActions.ammo_pack_deploy || 20 }}</span> per ammo pack deploy</li>
                            <li><span class="has-text-success">+{{ positiveActions.finale_win || 1000 }}</span> per finale win</li>
                            <br>
                            <li><span class="has-text-danger">{{ penalties.teammate_kill || -500 }}</span> for teammate kill</li>
                            <li><span class="has-text-danger">{{ penalties.friendly_fire_per_damage || -40 }}</span> per damage point dealt to teammate</li>
                        </ul>

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
                            <li><strong>Special Infected Kills × 6</strong> - Reward skilled gameplay</li>
                            <li><strong>Common Kills × 1</strong> - Basic zombie clearing</li>
                            <li><strong>Tank Kills × 100</strong> - Major threat elimination</li>
                            <li><strong>Witch Kills × 15</strong> - Precision kills</li>
                            <li><strong>Heals × 40</strong> - Team support</li>
                            <li><strong>Revives × 25</strong> - Saving teammates</li>
                            <li><strong>Defibs × 30</strong> - Critical rescues</li>
                            <li><strong>Finales Won × 1000</strong> - Campaign completion</li>
                            <li><strong>Molotovs Used × 5</strong> - Tactical throwables</li>
                            <li><strong>Pipe Bombs Used × 5</strong> - Area control</li>
                            <li><strong>Bile Bombs Used × 5</strong> - Distraction tactics</li>
                            <li><strong>Pills Used × 10</strong> - Self-care</li>
                            <li><strong>Adrenaline Used × 15</strong> - Speed boost usage</li>
                            <li><strong>Damage Taken Bonus × 0.5</strong> - Reward for taking less damage than average</li>
                        </ul>

                        <h6 class="title is-6 has-text-danger">Penalties:</h6>
                        <ul>
                            <li><strong>Teammate Kills × -100</strong> - Severe penalty</li>
                            <li><strong>Friendly Fire Damage × -2</strong> - Per damage point dealt to teammates</li>
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
      pointRules: null,
      loadingRules: true,
      rulesError: null
    }
  },
  async mounted() {
    await this.loadPointRules()
  },
  methods: {
    async loadPointRules() {
      try {
        this.loadingRules = true
        const response = await this.$http.get('/api/point-rules')
        
        if (response.data.success) {
          this.pointRules = response.data.rules
        } else {
          throw new Error(response.data.message || 'Failed to load point rules')
        }
      } catch (error) {
        console.error('Failed to load point rules:', error)
        this.rulesError = error.message
        // Fallback to default values if API fails
        this.pointRules = {
          point_values: {
            positive_actions: {
              common_kill: 1,
              headshot: 2,
              special_kill: 6,
              tank_kill_max: 100,
              tank_kill_solo: 20,
              tank_kill_melee: 50,
              witch_kill: 15,
              heal_teammate: 40,
              heal_teammate_critical: 60,
              revive_teammate: 25,
              defib_teammate: 50,
              teammate_save: 20,
              ammo_pack_deploy: 20,
              finale_win: 1000
            },
            penalties: {
              friendly_fire_per_damage: -40,
              teammate_kill: -500
            }
          }
        }
      } finally {
        this.loadingRules = false
      }
    }
  },
  computed: {
    rules() {
      return this.pointRules?.point_values || {}
    },
    positiveActions() {
      return this.rules.positive_actions || {}
    },
    penalties() {
      return this.rules.penalties || {}
    }
  }
}
</script>
