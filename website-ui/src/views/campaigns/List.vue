<template>
<div>
    <section class="hero is-dark">
        <div class="hero-body">
            <div class="container has-text-centered">
            <h1 class="title">
                Games
            </h1>
            <p class="subtitle is-4">{{total_campaigns | formatNumber}} total games played</p>
            </div>
        </div>
    </section>
    <br>
    <section class="section">
        <div class="container">
            <h2 class="title is-4 has-text-centered mb-6">Search Played Campaigns</h2>
        <div class="box">
            <b-field grouped multiline>
            <b-field label="Tag Selection">
                <!-- TODO: fetch from server -->
                <b-select v-model="filtered.filters.tag" placeholder="Select a tag">
                    <option value="any">Any</option>
                    <template v-for="entry in selectableTags">
                      <optgroup v-if="entry.list" :label="entry.label" :key="entry.label">
                        <option v-for="subentry in entry.list" :key="subentry.value" :value="subentry.value">
                          {{ subentry.label }}
                        </option>
                      </optgroup>
                      <option v-else :value="entry.value" :key="entry.value">{{ entry.label }}</option>
                    </template>
                </b-select>
            </b-field>
            <b-field label="Map Type">
                <b-select v-model="filtered.filters.type">
                    <option value="all">Any</option>
                    <option value="official">Official Only</option>
                    <option value="custom">Custom Only</option>
                </b-select>
            </b-field>
            <b-field label="Gamemode">
                <b-select v-model="filtered.filters.gamemode">
                    <option value="all">Any</option>
                    <option v-for="entry in selectableGamemodes" :key="entry.gamemode" :value="entry.gamemode">
                      {{ entry.label }} ({{entry.count.toLocaleString()}})
                    </option>
                </b-select>
            </b-field>
            <b-field label="Difficulty">
                <b-select v-model="filtered.filters.difficulty">
                    <option value="all">Any</option>
                    <option value="0">Easy</option>
                    <option value="1">Normal</option>
                    <option value="2">Advanced</option>
                    <option value="3">Expert</option>
                </b-select>
            </b-field>
        </b-field>
        </div>
            <div class="table-container">
                <div class="table-wrapper">
                    <table class="table is-fullwidth is-striped is-hoverable beautiful-table">
                    <thead>
                        <tr>
                            <th>Map</th>
                            <th>Mode</th>
                            <th>Difficulty</th>
                            <th>Date Played</th>
                            <th>Duration</th>
                            <th>Deaths</th>
                            <th>Commons</th>
                            <th>Players</th>
                            <th>Tags</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="campaign in filtered.list" :key="campaign.campaignID">
                            <td>
                                <router-link v-if="campaign.map" :to="'/campaigns/map/' + campaign.map" class="has-text-link">
                                    <strong>{{campaign.map_name ?? campaign.map}}</strong>
                                </router-link>
                                <strong v-else>{{campaign.map_name ?? 'Unknown Map'}}</strong>
                            </td>
                            <td>
                                <span class="tag is-info is-small">{{getGamemode(campaign.gamemode)}}</span>
                            </td>
                            <td>
                                <span class="tag is-warning is-small">{{formatDifficulty(campaign.difficulty)}}</span>
                            </td>
                            <td>
                                <span class="is-size-7">{{formatDate(campaign.date_end)}}</span>
                            </td>
                            <td>
                                <strong>{{getGameDuration(campaign.duration_seconds)}}</strong>
                            </td>
                            <td>
                                <strong>{{campaign.Deaths}}</strong>
                            </td>
                            <td>
                                <strong>{{campaign.CommonsKilled | formatNumber}}</strong>
                            </td>
                            <td>
                                <strong>{{campaign.playerCount}}</strong>
                            </td>
                            <td>
                                <b-taglist v-if="campaign.server_tags">
                                    <b-tag v-for="tag in parseTags(campaign.server_tags)" :key="tag" :type="getTagType(tag)" size="is-small">
                                        {{tag}}
                                    </b-tag>
                                </b-taglist>
                                <span v-else class="has-text-grey">-</span>
                            </td>
                            <td>
                                <div class="buttons are-small">
                                    <b-button v-if="campaign.map" type="is-primary" tag="router-link" :to="'/campaigns/map/' + campaign.map" size="is-small" expanded>
                                        Map Stats
                                    </b-button>
                                    <b-button v-else type="is-primary" size="is-small" disabled expanded>
                                        Map Stats
                                    </b-button>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                    </table>
                </div>
            </div>
        </div>
    </section>

    <section class="section">
        <div class="container">
            <h2 class="title is-4 has-text-centered mb-6">Recently Played Games</h2>
            <div class="columns is-multiline">
                <div v-for="campaign in recentCampaigns" class="column is-6-tablet is-4-desktop" :key="campaign.campaignID">
                    <div class="box" style="height: 100%;">
                        <div class="content">
                            <h5 class="title is-5 mb-3">
                                <router-link v-if="campaign.map" :to="'/campaigns/map/' + campaign.map" class="has-text-dark">
                                    {{campaign.map_name || campaign.map}}
                                </router-link>
                                <span v-else class="has-text-dark">{{campaign.map_name || 'Unknown Map'}}</span>
                            </h5>
                            <div class="tags mb-4">
                                <span class="tag is-info">{{getGamemode(campaign.gamemode)}}</span>
                                <span class="tag is-warning">{{formatDifficulty(campaign.difficulty)}}</span>
                            </div>
                        </div>

                        <div class="content">
                            <div class="columns is-mobile is-multiline">
                                <div class="column is-6 has-text-centered">
                                    <p class="heading">Duration</p>
                                    <p class="title is-5">{{getGameDuration(campaign.duration_seconds)}}</p>
                                </div>
                                <div class="column is-6 has-text-centered">
                                    <p class="heading">Deaths</p>
                                    <p class="title is-5">{{campaign.Deaths}}</p>
                                </div>
                                <div class="column is-6 has-text-centered">
                                    <p class="heading">Commons</p>
                                    <p class="title is-5">{{campaign.CommonsKilled | formatNumber}}</p>
                                </div>
                                <div class="column is-6 has-text-centered">
                                    <p class="heading">FF Damage</p>
                                    <p class="title is-5">{{campaign.FF | formatNumber}}</p>
                                </div>
                            </div>

                            <div v-if="campaign.server_tags" class="mb-3">
                                <b-taglist>
                                    <b-tag v-for="tag in parseTags(campaign.server_tags)" :key="tag" :type="getTagType(tag)" size="is-small">
                                        {{tag}}
                                    </b-tag>
                                </b-taglist>
                            </div>

                            <div class="buttons">
                                <b-button v-if="campaign.map" type="is-primary" tag="router-link" :to="'/campaigns/map/' + campaign.map" expanded size="is-small">
                                    View Map Statistics
                                </b-button>
                                <b-button v-else type="is-primary" expanded size="is-small" disabled>
                                    View Map Statistics
                                </b-button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>
</div>
</template>

<script>
import { getMapName, getMapImage } from '@/js/map'
import Settings from "@/assets/settings.json"
export default {
    data() {
        return {
            recentCampaigns: [],
            loading: true,
            total_campaigns: 0,
            selectedRecent: 0,
            filtered: {
                filters: {
                    tag: "any",
                    type: "all",
                    gamemode: 'all',
                    difficulty: 'all',
                    page: 0
                },

                list: [],
                loading: true,
            },
            gamemodes: []
        }
    },
    mounted() {
        /*let routerPage = parseInt(this.$route.params.page);
        if(isNaN(routerPage) || routerPage <= 0) routerPage = 1;
        this.current_page = routerPage;*/
        document.title = `Campaigns - L4D2 Stats Plugin`
        this.fetchGamemodes()
        this.fetchCampaigns()
        this.fetchFilteredCampaigns()
    },
    watch: {
        "filtered.filters": {
            handler() {
                this.fetchFilteredCampaigns()
            },
            deep: true
        }
    },
    computed: {
      selectableGamemodes() {
        const arr = []
        for(const entry of Object.values(this.gamemodes)) {
          const label = Settings.gamemodeLabels ? Settings.gamemodeLabels[entry.gamemode] : undefined
          arr.push({
            gamemode: entry.gamemode,
            count: entry.count,
            label: label ?? entry.gamemode
          })
        }
        return arr
      },
      selectableTags() {
        return Settings.selectableTags || []
      }
    },
    methods: {
        getMapName,
        getMapImage,
        async fetchGamemodes() {
          try {
            const res = await this.$http.get('/api/campaigns/values', { cache: true })
            this.gamemodes = res.data.gamemodes
          } catch(err) {
            console.error("Could not fetch values: ", err)
          }
        },
        fetchFilteredCampaigns() {
            this.filtered.loading = true;
            const queryParams = `?page=${this.filtered.filters.page}&perPage=16&tag=${this.filtered.filters.tag}&gamemode=${this.filtered.filters.gamemode}&type=${this.filtered.filters.type}&difficulty=${this.filtered.filters.difficulty}
            `.replace(/\s/,'')
            this.$http.get(`/api/campaigns${queryParams}`, { cache: true })
            .then(r => {
                r.data.recentCampaigns.forEach(v => v.campaignID = v.campaignID.substring(0, 8));
                this.filtered.list = r.data.recentCampaigns
            })
            .catch(err => {
                console.error('Fetch err', err)
                this.$buefy.snackbar.open({
                    duration: 5000,
                    message: 'Failed to fetch filtered campaigns',
                    type: 'is-danger',
                    position: 'is-bottom-left',
                    actionText: 'Retry',
                    onAction: () => this.fetchFilteredCampaigns()
                })
            })
            .finally(() => this.filtered.loading = false)
        },
        fetchCampaigns(page = 0) {
            this.loading = true;
            this.$http.get(`/api/campaigns/?page=${page}&perPage=8`, { cache: true })
            .then(r => {
                r.data.recentCampaigns.forEach(v => v.campaignID = v.campaignID.substring(0, 8));
                this.recentCampaigns = r.data.recentCampaigns;
                this.total_campaigns = r.data.total_campaigns
            })
            .catch(err => {
                console.error('Fetch err', err)
                this.$buefy.snackbar.open({
                    duration: 5000,
                    message: 'Failed to fetch campaigns',
                    type: 'is-danger',
                    position: 'is-bottom-left',
                    actionText: 'Retry',
                    onAction: () => this.fetchCampaigns()
                })
            })
            .finally(() => this.loading = false)
        },
        onPageChange(page) {
            this.fetchCampaigns(page);
        },
        getGamemode(inp) {
            switch(inp) {
                case "coop": return "Campaign"
                case "tankrun": return "Tank Run"
                case "rocketdude": return "RocketDude"
                default: {
                    return inp[0].toUpperCase() + inp.slice(1)
                }
            }
        },
        formatDifficulty(difficulty) {
            switch(difficulty) {
                case 0: return "Easy"
                case 1: return "Normal";
                case 2: return "Advanced"
                case 3: return "Expert"
            }
        },
        getGameDuration(d) {
            d = Number(d)
            if (isNaN(d) || d <= 0) {
                return "Unknown duration"
            }
            // d is in seconds, convert to minutes and hours
            const totalMinutes = Math.round(d / 60);
            const h = Math.floor(totalMinutes / 60);
            if(h >= 1) {
                const m = totalMinutes % 60;
                return `${h} hour${h == 1?'':'s'} & ${m} min`
            }
            return `${totalMinutes} minutes`
        },
        secondsToHms(d) {
            d = Number(d);
            const h = Math.floor(d / 3600);
            const m = Math.floor(d % 3600 / 60);
            //const s = Math.floor(d % 3600 % 60);

            const hDisplay = h > 0 ? h + (h == 1 ? " hour, " : " hours, ") : "";
            const mDisplay = m > 0 ? m + (m == 1 ? " minute " : " minutes ") : "";
            //const sDisplay = s > 0 ? s + (s == 1 ? " second" : " seconds") : "";
            return hDisplay + mDisplay;
        },
        getTagType(tag) {
            switch(tag.toLowerCase()) {
                case "dev": return 'is-danger'
                case "main": return "is-success"
                case "old": return "is-warning"
                case "vanilla+": return "is-dark"
                default: return ''
            }
        },
        parseTags(tags) {
            const arr = tags.split(',')
            if(arr.length > 0 && arr[0] === "prod") return arr.slice(1)
            return arr;
        },
        formatDate(inp) {
            if(inp <= 0 || isNaN(inp)) return ""
            try {
                const date = new Date(inp * 1000).toLocaleString()
                return date;
            }catch(err) {
                return "Unknown"
            }
        },
    }
}

</script>
<style>
.number-cell {
  color: blue;
}
.table td {
    vertical-align: middle;;
}
.has-text-dark {
    color: #363636 !important;
}
.has-text-dark:hover {
    color: #3273dc !important;
}
.has-text-link {
    color: #3273dc !important;
}
.has-text-link:hover {
    color: #2366d1 !important;
}
.buttons.are-small .button {
    margin-bottom: 0;
}

/* Beautiful Table Styles */
.table-container {
    margin: 10px 0;
}

.table-wrapper {
    background: white;
    border-radius: 4px;
    overflow: auto;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    max-height: 80vh;
    position: relative;
    overflow-x: auto;
    overflow-y: auto;
    border: 1px solid #e0e0e0;
}

.table-wrapper::-webkit-scrollbar {
    width: 8px;
    height: 8px;
}

.table-wrapper::-webkit-scrollbar-track {
    background: #f1f1f1;
    border-radius: 4px;
}

.table-wrapper::-webkit-scrollbar-thumb {
    background: #167df0;
    border-radius: 4px;
}

.table-wrapper::-webkit-scrollbar-thumb:hover {
    background: #1366d6;
}

.table-wrapper::-webkit-scrollbar-corner {
    background: #f1f1f1;
}

.beautiful-table {
    margin-bottom: 0 !important;
}

.beautiful-table thead th {
    background: #167df0 !important;
    color: white !important;
    border: none !important;
    padding: 15px 10px !important;
    font-weight: 600 !important;
    text-transform: uppercase !important;
    font-size: 0.85rem !important;
    letter-spacing: 0.5px !important;
    position: sticky !important;
    top: 0 !important;
    z-index: 10 !important;
}

.beautiful-table tbody tr {
    transition: all 0.3s ease !important;
    border-bottom: 1px solid #f5f5f5 !important;
}

.beautiful-table tbody tr:hover {
    background: rgba(22, 125, 240, 0.05) !important;
}

.beautiful-table tbody tr:nth-child(even) {
    background-color: #fafafa !important;
}

.beautiful-table tbody tr:nth-child(even):hover {
    background: rgba(22, 125, 240, 0.08) !important;
}

.beautiful-table tbody td {
    vertical-align: middle !important;
    padding: 12px 10px !important;
    border: none !important;
    font-size: 0.9rem !important;
}

.beautiful-table .button.is-primary {
    background: #167df0 !important;
    border: none !important;
    color: white !important;
}

.beautiful-table .button.is-primary:hover {
    background: #1366d6 !important;
}
</style>
