<template>
<div>
    <section class="hero is-dark">
        <div class="hero-body">
            <div class="container">
                <div class="columns">
                    <div v-if="mapData && !loading" class="column">
                        <nav class="breadcrumb has-arrow-separator" aria-label="breadcrumbs">
                            <ul>
                                <li><router-link to="/campaigns">Games</router-link></li>
                                <li class="is-active"><a href="#" aria-current="page">{{mapData.map.name || mapData.map.mapid}}</a></li>
                            </ul>
                        </nav>
                        <h1 class="title">
                            {{mapData.map.name || mapData.map.mapid}}
                            <a v-if="$SHARE_URL" style="color: white" @click="getShareLink()"><b-icon icon="share" /></a>
                        </h1>
                        <p class="subtitle is-4">
                            {{mapData.aggregated_stats.total_players}} players • 
                            {{mapData.map.chapter_count ? mapData.map.chapter_count + ' chapters' : 'Custom map'}}
                        </p>
                        <hr>
                        <p class="is-size-4">
                            Map Campaign Statistics
                        </p>
                    </div>
                    <div v-else-if="!loading && error" class="column">
                        <h1 class="title">
                            {{error.message || 'Map Not Found'}}
                        </h1>
                        <p class="subtitle">
                            The requested map campaign details could not be found.
                        </p>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <b-loading :is-full-page="false" :active="loading" />

    <!-- Aggregated Statistics Section -->
    <section v-if="mapData && !loading" class="section">
        <div class="container">
            <h2 class="title is-4 has-text-centered mb-6">Overall Map Statistics</h2>
            
            <!-- Combat Stats -->
            <div class="box">
                <h3 class="title is-5 mb-4">Combat Statistics</h3>
                <nav class="level">
                    <div class="level-item has-text-centered">
                        <div>
                            <p class="heading">Zombies Killed</p>
                            <p class="title">{{formatNumber(mapData.aggregated_stats.total_zombies_killed)}}</p>
                        </div>
                    </div>
                    <div class="level-item has-text-centered">
                        <div>
                            <p class="heading">Specials Killed</p>
                            <p class="title">{{formatNumber(mapData.aggregated_stats.total_specials_killed)}}</p>
                        </div>
                    </div>
                    <div class="level-item has-text-centered">
                        <div>
                            <p class="heading">Melee Kills</p>
                            <p class="title">{{formatNumber(mapData.aggregated_stats.total_melee_kills)}}</p>
                        </div>
                    </div>
                </nav>
            </div>

            <!-- Damage Stats -->
            <div class="box">
                <h3 class="title is-5 mb-4">Damage Statistics</h3>
                <nav class="level">
                    <div class="level-item has-text-centered">
                        <div>
                            <p class="heading">Damage Taken</p>
                            <p class="title">{{formatNumber(mapData.aggregated_stats.total_damage_taken)}}</p>
                        </div>
                    </div>
                    <div class="level-item has-text-centered">
                        <div>
                            <p class="heading">Friendly Fire Count</p>
                            <p class="title">{{formatNumber(mapData.aggregated_stats.total_friendly_fire_count)}}</p>
                        </div>
                    </div>
                    <div class="level-item has-text-centered">
                        <div>
                            <p class="heading">FF Damage Dealt</p>
                            <p class="title">{{formatNumber(mapData.aggregated_stats.total_friendly_fire_damage)}}</p>
                        </div>
                    </div>
                </nav>
            </div>

            <!-- Items Used -->
            <div class="box">
                <h3 class="title is-5 mb-4">Items Used</h3>
                <nav class="level">
                    <div class="level-item has-text-centered">
                        <div>
                            <p class="heading">Molotovs</p>
                            <p class="title">{{formatNumber(mapData.aggregated_stats.total_molotovs_used)}}</p>
                        </div>
                    </div>
                    <div class="level-item has-text-centered">
                        <div>
                            <p class="heading">Pipebombs</p>
                            <p class="title">{{formatNumber(mapData.aggregated_stats.total_pipebombs_used)}}</p>
                        </div>
                    </div>
                    <div class="level-item has-text-centered">
                        <div>
                            <p class="heading">Biles</p>
                            <p class="title">{{formatNumber(mapData.aggregated_stats.total_biles_used)}}</p>
                        </div>
                    </div>
                    <div class="level-item has-text-centered">
                        <div>
                            <p class="heading">Kits Used</p>
                            <p class="title">{{formatNumber(mapData.aggregated_stats.total_kits_used)}}</p>
                        </div>
                    </div>
                </nav>
            </div>

            <!-- Player Status & Misc -->
            <div class="columns">
                <div class="column">
                    <div class="box">
                        <h3 class="title is-5 mb-4">Player Status</h3>
                        <nav class="level">
                            <div class="level-item has-text-centered">
                                <div>
                                    <p class="heading">Incaps</p>
                                    <p class="title">{{formatNumber(mapData.aggregated_stats.total_incaps)}}</p>
                                </div>
                            </div>
                            <div class="level-item has-text-centered">
                                <div>
                                    <p class="heading">Deaths</p>
                                    <p class="title">{{formatNumber(mapData.aggregated_stats.total_deaths)}}</p>
                                </div>
                            </div>
                        </nav>
                    </div>
                </div>
                <div class="column">
                    <div class="box">
                        <h3 class="title is-5 mb-4">Session Info</h3>
                        <nav class="level">
                            <div class="level-item has-text-centered">
                                <div>
                                    <p class="heading">Average Ping</p>
                                    <p class="title">{{mapData.aggregated_stats.avg_ping}} ms</p>
                                </div>
                            </div>
                            <div class="level-item has-text-centered">
                                <div>
                                    <p class="heading">Total Honks</p>
                                    <p class="title">{{formatNumber(mapData.aggregated_stats.total_honks)}}</p>
                                </div>
                            </div>
                        </nav>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Player Statistics Table -->
    <section v-if="mapData && !loading" class="section">
        <div class="container">
            <h2 class="title is-4 has-text-centered mb-6">Individual Player Performance</h2>
            <div class="box">
                <b-table 
                    :data="mapData.player_stats" 
                    :loading="loading"
                    :paginated="true"
                    :per-page="10"
                    :pagination-simple="false"
                    :default-sort="['session_start', 'desc']"
                    detailed
                    detail-key="steamid"
                    show-detail-icon>
                    
                    <b-table-column field="last_alias" label="Player" sortable v-slot="props">
                        <router-link :to="'/user/' + props.row.steamid" class="has-text-link">
                            {{props.row.last_alias}}
                        </router-link>
                    </b-table-column>

                    <b-table-column field="session_start_formatted" label="Date Played" sortable v-slot="props">
                        {{formatSessionDate(props.row.session_start_formatted)}}
                    </b-table-column>

                    <b-table-column field="common_kills" label="Zombies" numeric sortable v-slot="props">
                        {{formatNumber(props.row.common_kills || 0)}}
                    </b-table-column>

                    <b-table-column field="specials_killed" label="Specials" numeric sortable v-slot="props">
                        {{formatNumber(props.row.specials_killed || 0)}}
                    </b-table-column>

                    <b-table-column field="damage_taken" label="Damage Taken" numeric sortable v-slot="props">
                        {{formatNumber(props.row.damage_taken || 0)}}
                    </b-table-column>

                    <b-table-column field="incaps" label="Incaps" numeric sortable v-slot="props">
                        {{formatNumber(props.row.incaps || 0)}}
                    </b-table-column>

                    <b-table-column field="deaths" label="Deaths" numeric sortable v-slot="props">
                        {{formatNumber(props.row.deaths || 0)}}
                    </b-table-column>

                    <b-table-column field="ping" label="Ping" numeric sortable v-slot="props">
                        {{props.row.ping ? props.row.ping + ' ms' : 'N/A'}}
                    </b-table-column>

                    <template #detail="props">
                        <div class="content">
                            <div class="columns">
                                <div class="column">
                                    <strong>Combat Details:</strong>
                                    <ul>
                                        <li>Melee Kills: {{formatNumber(props.row.melee_kills || 0)}}</li>
                                        <li>Friendly Fire Count: {{formatNumber(props.row.friendly_fire_count || 0)}}</li>
                                        <li>FF Damage Dealt: {{formatNumber(props.row.friendly_fire_damage || 0)}}</li>
                                    </ul>
                                </div>
                                <div class="column">
                                    <strong>Items Used:</strong>
                                    <ul>
                                        <li>Molotovs: {{formatNumber(props.row.molotovs_used || 0)}}</li>
                                        <li>Pipebombs: {{formatNumber(props.row.pipebombs_used || 0)}}</li>
                                        <li>Biles: {{formatNumber(props.row.biles_used || 0)}}</li>
                                        <li>Kits: {{formatNumber(props.row.kits_used || 0)}}</li>
                                    </ul>
                                </div>
                                <div class="column">
                                    <strong>Session Info:</strong>
                                    <ul>
                                        <li>Duration: {{props.row.session_duration_minutes ? props.row.session_duration_minutes + ' min' : 'N/A'}}</li>
                                        <li>Total Honks: {{formatNumber(props.row.total_honks || 0)}}</li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </template>
                </b-table>
            </div>
        </div>
    </section>
</div>
</template>

<script>
export default {
    data() {
        return {
            mapData: null,
            loading: true,
            error: null
        }
    },
    mounted() {
        this.fetchMapCampaignDetails()
    },
    watch: {
        '$route'() {
            this.fetchMapCampaignDetails()
        }
    },
    methods: {
        fetchMapCampaignDetails() {
            this.loading = true
            this.error = null
            
            const mapId = this.$route.params.mapId
            document.title = `Map Campaign Details - ${mapId} - L4D2 Stats Plugin`
            
            this.$http.get(`/api/campaigns/map/${mapId}`)
            .then(response => {
                this.mapData = response.data
                document.title = `${this.mapData.map.name || mapId} - Campaign Details - L4D2 Stats Plugin`
            })
            .catch(error => {
                console.error('Failed to fetch map campaign details:', error)
                this.error = error.response?.data || { message: 'Failed to load map details' }
                this.$buefy.snackbar.open({
                    duration: 5000,
                    message: 'Failed to fetch map campaign details',
                    type: 'is-danger',
                    position: 'is-bottom-left',
                    actionText: 'Retry',
                    onAction: () => this.fetchMapCampaignDetails()
                })
            })
            .finally(() => {
                this.loading = false
            })
        },
        formatNumber(num) {
            if (num === null || num === undefined) return '0'
            return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")
        },
        formatSessionDate(dateString) {
            if (!dateString) return 'N/A'
            const date = new Date(dateString)
            return date.toLocaleDateString('en-US', {
                month: '2-digit',
                day: '2-digit', 
                year: 'numeric'
            }) + ' at ' + date.toLocaleTimeString('en-US', {
                hour: 'numeric',
                minute: '2-digit',
                hour12: true
            })
        },
        getShareLink() {
            if (this.$SHARE_URL) {
                const url = `${this.$SHARE_URL}/campaigns/map/${this.$route.params.mapId}`
                navigator.clipboard.writeText(url).then(() => {
                    this.$buefy.snackbar.open({
                        message: 'Share link copied to clipboard!',
                        type: 'is-success',
                        position: 'is-bottom-left'
                    })
                })
            }
        }
    }
}
</script>

<style scoped>
.breadcrumb {
    margin-bottom: 1rem;
}

.breadcrumb a {
    color: #dbdbdb;
}

.breadcrumb li.is-active a {
    color: white;
}

.box {
    margin-bottom: 2rem;
}

.level {
    margin-bottom: 0;
}

.has-text-link {
    color: #3273dc !important;
}

.has-text-link:hover {
    color: #2366d1 !important;
}
</style>
