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
    <div class="container">
        <h5 class="title is-5 has-text-centered">Recently Played Games</h5>
        <div class="columns is-multiline">
            <div v-for="campaign in recentCampaigns" class="column is-6-tablet is-4-desktop is-3-widescreen" :key="campaign.campaignID">
                <div class="card">
                    <div class="card-image">
                        <figure class="image is-4by3">
                            <img :src="getMapImage(campaign.map)" style="object-fit: cover;" />
                        </figure>
                    </div>
                    <div class="card-content">
                        <div class="content">
                            <h6 class="title is-6 mb-2">{{campaign.map_name || campaign.map}}</h6>
                            <div class="tags mb-3">
                                <span class="tag is-info">{{getGamemode(campaign.gamemode)}}</span>
                                <span class="tag is-warning">{{formatDifficulty(campaign.difficulty)}}</span>
                            </div>

                            <div class="columns is-mobile is-gapless">
                                <div class="column has-text-centered">
                                    <p class="heading">Duration</p>
                                    <p class="title is-6">{{getGameDuration((campaign.date_end-campaign.date_start))}}</p>
                                </div>
                                <div class="column has-text-centered">
                                    <p class="heading">Deaths</p>
                                    <p class="title is-6">{{campaign.Deaths}}</p>
                                </div>
                            </div>

                            <div class="columns is-mobile is-gapless">
                                <div class="column has-text-centered">
                                    <p class="heading">Commons</p>
                                    <p class="title is-6">{{campaign.CommonsKilled | formatNumber}}</p>
                                </div>
                                <div class="column has-text-centered">
                                    <p class="heading">FF Damage</p>
                                    <p class="title is-6">{{campaign.FF | formatNumber}}</p>
                                </div>
                            </div>

                            <div v-if="campaign.server_tags" class="mb-3">
                                <b-taglist>
                                    <b-tag v-for="tag in parseTags(campaign.server_tags)" :key="tag" :type="getTagType(tag)" size="is-small">
                                        {{tag}}
                                    </b-tag>
                                </b-taglist>
                            </div>
                        </div>
                    </div>
                    <footer class="card-footer">
                        <router-link :to="'/campaigns/' + campaign.campaignID" class="card-footer-item">
                            View Details
                        </router-link>
                    </footer>
                </div>
            </div>
        </div>
    </div>
    <hr>
    <div class="container">
        <h5 class="title is-5 has-text-centered">Search Played Campaigns</h5>
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
        <div class="columns is-multiline">
            <div v-for="campaign in filtered.list" class="column is-6-tablet is-4-desktop is-3-widescreen" :key="campaign.campaignID">
                <div class="card">
                    <div class="card-image">
                        <figure class="image is-4by3">
                            <img :src="getMapImage(campaign.map)" style="object-fit: cover;" />
                        </figure>
                    </div>
                    <div class="card-content">
                        <div class="content">
                            <h6 class="title is-6 mb-2">{{campaign.map_name ?? campaign.map}}</h6>
                            <div class="tags mb-3">
                                <span class="tag is-info">{{getGamemode(campaign.gamemode)}}</span>
                                <span class="tag is-warning">{{formatDifficulty(campaign.difficulty)}}</span>
                            </div>
                            <p class="is-size-7 has-text-grey mb-3">
                                Played <strong>{{formatDate(campaign.date_end)}}</strong>
                            </p>

                            <div class="columns is-mobile is-gapless">
                                <div class="column has-text-centered">
                                    <p class="heading">Duration</p>
                                    <p class="title is-6">{{secondsToHms((campaign.date_end-campaign.date_start))}}</p>
                                </div>
                                <div class="column has-text-centered">
                                    <p class="heading">Deaths</p>
                                    <p class="title is-6">{{campaign.Deaths}}</p>
                                </div>
                            </div>

                            <div class="columns is-mobile is-gapless">
                                <div class="column has-text-centered">
                                    <p class="heading">Commons</p>
                                    <p class="title is-6">{{campaign.CommonsKilled | formatNumber}}</p>
                                </div>
                                <div class="column has-text-centered">
                                    <p class="heading">Players</p>
                                    <p class="title is-6">{{campaign.playerCount}}</p>
                                </div>
                            </div>

                            <div v-if="campaign.server_tags" class="mb-3">
                                <b-taglist>
                                    <b-tag v-for="tag in parseTags(campaign.server_tags)" :key="tag" :type="getTagType(tag)" size="is-small">
                                        {{tag}}
                                    </b-tag>
                                </b-taglist>
                            </div>
                        </div>
                    </div>
                    <footer class="card-footer">
                        <router-link :to="'/campaigns/' + campaign.campaignID" class="card-footer-item">
                            View Details
                        </router-link>
                    </footer>
                </div>
            </div>
        </div>
        <br>
    </div>
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
            const h = Math.floor(d / 3600);
            if(h >= 1) {
                const m = Math.floor(d % 3600 / 60);
                return `${h} hour${h == 1?'':'s'} & ${m} min`
            }
            const m = Math.round(d / 60)
            return `${m} minutes`
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
</style>
