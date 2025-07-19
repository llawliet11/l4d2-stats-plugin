<template>
  <div>
      <h2 class='title is-2'>Points History</h2>
      <b-table
          :data="history"
          :loading="loading"

          paginated
          backend-pagination
          :current-page="current_page"
          per-page=50
          :total="total_points"
          @page-change="onPageChange"
      >
            <b-table-column field="type" label="Action" v-slot="props">
                {{ getActionDescription(props.row) }}
            </b-table-column>
            <b-table-column field="amount" label="Points" centered v-slot="props">
                <span class="has-text-success" v-if="props.row.amount > 0">+{{ props.row.amount }}</span>
                <span class="has-text-danger" v-else>{{ props.row.amount }}</span>
            </b-table-column>
            <b-table-column field="timestamp" label="Timestamp" centered v-slot="props">
                {{ formatDate(props.row.timestamp) }}
            </b-table-column>
          <template slot="empty">
              <section class="section">
                  <div class="content has-text-grey has-text-centered">
                      <p>{{user.last_alias}} has no recorded points history</p>
                  </div>
              </section>
          </template>
      </b-table>
  </div>
  </template>

  <script>
  const POINT_TYPE_DISPLAY = [
    "Generic",  // PType_Generic = 0,
    "Finish Campaign",  // PType_FinishCampaign,
    "Common Kill",  // PType_CommonKill,
    "Special Kill",  // PType_SpecialKill,
    "Tank Kill",  // PType_TankKill,
    "Witch Kill",  // PType_WitchKill,
    "Solo Tank Kill", // PType_TankKill_Solo
    "Melee-Only Tank Kill",  // PType_TankKill_Melee,
    "Headshot",  // PType_Headshot,
    "Friendly Fire Penalty",  // PType_FriendlyFire,
    "Healing Teammate",  // PType_HealOther,
    "Reviving Teammate",  // PType_ReviveOther,
    "Defibbing Teammate",  // PType_ResurrectOther,
    "Deploying Ammo",  // PType_DeployAmmo
    // NEW TYPES - Base Points:
    "Witch Crown",  // PType_WitchCrown = 14
    "Melee Kill",  // PType_MeleeKill = 15
    "Pills Used",  // PType_PillUse = 16
    "Adrenaline Used",  // PType_AdrenalineUse = 17
    "Molotov Used",  // PType_MolotovUse = 18
    "Pipe Bomb Used",  // PType_PipeUse = 19
    "Bile Bomb Used",  // PType_BileUse = 20
    "Tank Damage",  // PType_TankDamage = 21
    "Cleared Pinned Teammate",  // PType_ClearPinned = 22
    "Smoker Self Clear",  // PType_SmokerSelfClear = 23
    "Hunter Deadstop",  // PType_HunterDeadstop = 24
    "Boomer Bile Hit",  // PType_BoomerBileHit = 25
    // NEW TYPES - Penalties:
    "Death Penalty",  // PType_Death = 26
    "Car Alarm Penalty",  // PType_CarAlarm = 27
    "Pinned Penalty",  // PType_TimesPinned = 28
    "Tank Rock Hit Penalty",  // PType_TankRockHit = 29
    "Clown Honk Penalty",  // PType_ClownHonk = 30
    "Boomer Bile Self Penalty",  // PType_BoomerBileSelf = 31
    "Teammate Kill Penalty"  // PType_TeammateKill = 32
  ]
  export default {
    metaInfo() {
        return {
          title: "Points History"
        }
      },
      props: ['user'],
      data() {
          return {
              history: [],
              loading: true,
              current_page: 1,
              total_history: 0
          }
      },
      mounted() {
          let routerPage = parseInt(this.$route.params.page);
          if(isNaN(routerPage) || routerPage <= 0) routerPage = 1;
          this.current_page = routerPage;
          this.fetchPointsHistory()
      },
      methods: {
        onPageChange(page) {
          this.current_page = page
          this.fetchPointsHistory()
        },
        getPointType(type) {
          return POINT_TYPE_DISPLAY[type] ?? type
        },
        getActionDescription(row) {
          const baseType = this.getPointType(row.type);
          
          // Add specific descriptions for friendly fire based on amount
          if (row.type === 9) { // PType_FriendlyFire
            switch(row.amount) {
              case -500:
                return "Teammate Kill";
              case -40:
                return "Teammate Damage (11+ HP)";
              case -20:
                return "Teammate Damage (6-10 HP)";
              case -10:
                return "Teammate Damage (1-5 HP)";
              default:
                return baseType;
            }
          }
          
          return baseType;
        },
        formatDate(date) {
          const d = new Date(date * 1000)
          return `${d.toLocaleDateString()} at ${d.toLocaleTimeString()}`
        },
        fetchPointsHistory() {
            this.loading = true;
            this.$http.get(`/api/user/${this.user.steamid}/points/${this.current_page}`, { cache: true })
            .then(r => {
                this.history = r.data.history;
                this.total_points = r.data.total;
            })
            .catch(err => {
                console.error('Fetch err', err)
                this.$buefy.snackbar.open({
                    duration: 5000,
                    message: 'Failed to fetch points history.',
                    type: 'is-danger',
                    position: 'is-bottom-left',
                    actionText: 'Retry',
                    onAction: () => this.fetchPointsHistory()
                })
            })
            .finally(() => this.loading = false)
        }
      }
  }
  </script>

  <style>
  .number-cell {
      color: blue;
  }
  </style>
