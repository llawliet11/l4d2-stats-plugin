<template>
<div class="has-text-white" style="background-color: #4c516d">
    <section class="hero is-dark">
        <div class="hero-body">
            <div class="container">
                <div class="columns">
                    <div v-if="mapData && !loading" class="column">
                        <nav class="breadcrumb has-arrow-separator" aria-label="breadcrumbs">
                            <ul>
                                <li><router-link to="/maps">Campaigns</router-link></li>
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

    <!-- Individual Player Performance Section -->
    <div v-if="mapData && !loading" class="container is-fluid">
        <br>
        <h2 class="title is-4 has-text-centered has-text-white mb-6">Individual Player Performance</h2>
        <div class="columns is-multiline">
            <div v-for="(player, index) in mapData.player_stats" class="column is-3" :key="player.steamid">
                <div :class="[{'bg-mvp': index === 0}, 'box', 'has-text-centered']" style="position: relative">
                    <router-link :to="'/user/' + player.steamid">
                        <img class="is-inline-block is-pulled-left image is-128x128" :src="'/img/portraits/' + getCharacterName(index) + '.png'" />
                    </router-link>
                    <h6 class="title is-6">
                        <router-link :to="'/user/' + player.steamid" class="has-text-info">
                            {{player.last_alias ? player.last_alias.substring(0,20) : 'Unknown'}}
                        </router-link>
                    </h6>
                    <p class="subtitle is-6">{{formatSessionDate(player.session_start_formatted)}}</p>
                    <hr class="player-divider">
                    <ul class="has-text-right">
                        <li><span class="has-text-info">{{formatNumber(player.common_kills || 0)}}</span> commons killed</li>
                        <li><span class="has-text-info">{{formatNumber(player.specials_killed || 0)}}</span> specials killed</li>
                        <li><span class="has-text-info">{{formatNumber(player.friendly_fire_count || 0)}}</span> friendly fire count</li>
                        <li><span class="has-text-info">{{formatNumber(player.friendly_fire_damage || 0)}}</span> friendly fire damage</li>
                        <li><span class="has-text-info">{{formatNumber(player.damage_taken || 0)}}</span> damage taken</li>
                        <li><span class="has-text-info">{{formatNumber(player.melee_kills || 0)}}</span> melee kills</li>
                        <li><span class="has-text-info">{{formatNumber(player.incaps || 0)}}</span> incaps</li>
                        <li><span class="has-text-info">{{formatNumber(player.deaths || 0)}}</span> deaths</li>
                        <li v-if="player.total_honks > 0"><span class="has-text-info">{{formatNumber(player.total_honks)}}</span> clown honks</li>
                    </ul>
                    <br>
                    <b-button type="is-info" tag="router-link" :to="'/user/' + player.steamid" expanded>View Profile</b-button>
                    <div v-if="index === 0" class="ribbon ribbon-top-left"><span>Top Performer</span></div>
                </div>
            </div>
        </div>
    </div>

    <hr>

    <!-- Overall Map Statistics Section -->
    <div v-if="mapData && !loading" class="container is-fluid">
        <div class="columns">
            <div class="column">
                <nav class="level">
                    <div class="level-item has-text-centered">
                        <div>
                            <p class="heading">Zombies Killed</p>
                            <p class="title has-text-white">{{formatNumber(mapData.aggregated_stats.total_zombies_killed)}}</p>
                        </div>
                    </div>
                    <div class="level-item has-text-centered">
                        <div>
                            <p class="heading">Specials Killed</p>
                            <p class="title has-text-white">{{formatNumber(mapData.aggregated_stats.total_specials_killed)}}</p>
                        </div>
                    </div>
                    <div class="level-item has-text-centered">
                        <div>
                            <p class="heading">Damage Taken</p>
                            <p class="title has-text-white">{{formatNumber(mapData.aggregated_stats.total_damage_taken)}}</p>
                        </div>
                    </div>
                    <div class="level-item has-text-centered">
                        <div>
                            <p class="heading">Melee Kills</p>
                            <p class="title has-text-white">{{formatNumber(mapData.aggregated_stats.total_melee_kills)}}</p>
                        </div>
                    </div>
                    <div class="level-item has-text-centered">
                        <div>
                            <p class="heading">Friendly Fire Count</p>
                            <p class="title has-text-white">{{formatNumber(mapData.aggregated_stats.total_friendly_fire_count)}}</p>
                        </div>
                    </div>
                    <div class="level-item has-text-centered">
                        <div>
                            <p class="heading">Friendly Fire Damage Dealt</p>
                            <p class="title has-text-white">{{formatNumber(mapData.aggregated_stats.total_friendly_fire_damage)}}</p>
                        </div>
                    </div>
                </nav>

                <div class="tile is-ancestor">
                    <div class="tile is-vertical">
                        <div class="tile">
                            <div class="tile is-parent is-vertical">
                                <article class="tile is-child notification is-info">
                                    <p>&nbsp;</p>
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
                                    </nav>
                                </article>
                            </div>
                            <div class="tile is-parent is-vertical">
                                <article class="tile is-child notification has-text-white" style="background-color: #d6405e">
                                    <p>&nbsp;</p>
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
                                        <div class="level-item has-text-centered">
                                            <div>
                                                <p class="heading">Kits Used</p>
                                                <p class="title">{{formatNumber(mapData.aggregated_stats.total_kits_used)}}</p>
                                            </div>
                                        </div>
                                    </nav>
                                </article>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="column is-3">
                <div class="box">
                    <div class="has-text-left">
                        <strong>Map</strong>
                        <p>{{mapData.map.name || mapData.map.mapid}} <em class="is-pulled-right">({{mapData.map.mapid}})</em></p>
                        <strong>Total Players</strong>
                        <p>{{mapData.aggregated_stats.total_players}} unique players</p>
                        <strong>Map Type</strong>
                        <p>{{mapData.map.chapter_count ? mapData.map.chapter_count + ' chapters' : 'Custom map'}}</p>
                        <span v-if="mapData.aggregated_stats.avg_ping > 0">
                            <strong>Average Ping</strong>
                            <p>{{mapData.aggregated_stats.avg_ping}} ms</p>
                        </span>
                        <span v-if="mapData.aggregated_stats.total_honks > 0">
                            <strong>Total Honks</strong>
                            <p>{{formatNumber(mapData.aggregated_stats.total_honks)}}</p>
                        </span>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <br>
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

            // Validate mapId parameter
            if (!mapId || mapId.trim() === '' || mapId === 'undefined' || mapId === 'null') {
                console.warn('Invalid mapId parameter:', mapId)
                this.error = {
                    error: 'INVALID_MAP_ID',
                    message: 'Invalid map ID provided'
                }
                this.loading = false
                document.title = `Invalid Map - L4D2 Stats Plugin`
                return
            }

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
        },
        getCharacterName(index) {
            // Assign characters based on player index for consistency
            const characters = ['gambler', 'producer', 'mechanic', 'coach', 'namvet', 'teenangst', 'biker', 'manager']
            return characters[index % characters.length]
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

.player-divider {
    margin: 0.5rem 0;
}

.bg-mvp {
    background-color: rgb(132, 218, 230) !important;
}

.ribbon {
    width: 150px;
    height: 150px;
    overflow: hidden;
    position: absolute;
}

.ribbon::before,
.ribbon::after {
    position: absolute;
    z-index: -1;
    content: '';
    display: block;
    border: 5px solid #2980b9;
}

.ribbon span {
    position: absolute;
    display: block;
    width: 225px;
    padding: 15px 0;
    background-color: #3498db;
    box-shadow: 0 5px 10px rgba(0,0,0,.1);
    color: #fff;
    font: 700 18px/1 'Lato', sans-serif;
    text-shadow: 0 1px 1px rgba(0,0,0,.2);
    text-transform: uppercase;
    text-align: center;
}

.ribbon-top-left {
    top: -10px;
    left: -10px;
}

.ribbon-top-left::before,
.ribbon-top-left::after {
    border-top-color: transparent;
    border-left-color: transparent;
}

.ribbon-top-left::before {
    top: 0;
    right: 0;
}

.ribbon-top-left::after {
    bottom: 0;
    left: 0;
}

.ribbon-top-left span {
    right: -25px;
    top: 30px;
    transform: rotate(-45deg);
}
</style>
