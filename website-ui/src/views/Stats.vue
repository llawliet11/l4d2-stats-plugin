<template>
<div>
    <section class="hero is-dark">
        <div class="hero-body">
            <div class="container has-text-centered">
            <h1 class="title">
                Statistics
            </h1>
            <p class="subtitle is-4">A summarization of all recorded sessions</p>
            </div>
        </div>
    </section>
    <br>
    <div class="container" v-if="totals && averages">
        <!-- Totals Section -->
        <div class="box has-background-primary-light mb-6">
            <h2 class="title is-4 has-text-primary has-text-centered mb-5">
                <span class="icon-text">
                    <span class="icon">
                        <i class="fas fa-chart-bar"></i>
                    </span>
                    <span>Total Statistics</span>
                </span>
            </h2>
            <div class="columns is-multiline">
                <div class="column is-one-fifth">
                    <div class="has-text-centered p-4">
                        <p class="heading has-text-weight-semibold">Games Played</p>
                        <p class="title is-3 has-text-primary"><ICountUp :endVal="totals.total_games" /></p>
                    </div>
                </div>
                <div class="column is-one-fifth">
                    <div class="has-text-centered p-4">
                        <p class="heading has-text-weight-semibold">Total Playtime</p>
                        <p class="title is-3 has-text-info"><ICountUp :endVal="Math.round(totals.game_duration / 60 / 60)" /> hours</p>
                    </div>
                </div>
                <div class="column is-one-fifth">
                    <div class="has-text-centered p-4">
                        <p class="heading has-text-weight-semibold">Zombies Killed</p>
                        <p class="title is-3 has-text-success"><ICountUp :endVal="totals.zombie_kills" /></p>
                    </div>
                </div>
                <div class="column is-one-fifth">
                    <div class="has-text-centered p-4">
                        <p class="heading has-text-weight-semibold">Total FF Damage</p>
                        <p class="title is-3 has-text-danger"><ICountUp :endVal="totals.survivor_ff" /> HP</p>
                    </div>
                </div>
                <div class="column is-one-fifth">
                    <div class="has-text-centered p-4">
                        <p class="heading has-text-weight-semibold">Unique Players</p>
                        <p class="title is-3 has-text-link"><ICountUp :endVal="totals.total_users" /></p>
                    </div>
                </div>
            </div>
            <SummaryBit :values="totals" />
        </div>
        <!-- Averages Section -->
        <div class="box has-background-info-light mb-6">
            <h2 class="title is-4 has-text-info has-text-centered mb-5">
                <span class="icon-text">
                    <span class="icon">
                        <i class="fas fa-calculator"></i>
                    </span>
                    <span>Average Statistics</span>
                </span>
            </h2>
            <div class="columns is-multiline">
                <div class="column is-one-fifth">
                    <div class="has-text-centered p-4">
                        <p class="heading has-text-weight-semibold">Game Duration</p>
                        <p class="title is-3 has-text-info"><ICountUp :endVal="Math.round(averages.game_duration / 60)" /> min</p>
                    </div>
                </div>
                <div class="column is-one-fifth">
                    <div class="has-text-centered p-4">
                        <p class="heading has-text-weight-semibold">Zombies Killed</p>
                        <p class="title is-3 has-text-success"><ICountUp :endVal="Math.round(averages.zombie_kills)" /></p>
                    </div>
                </div>
                <div class="column is-one-fifth">
                    <div class="has-text-centered p-4">
                        <p class="heading has-text-weight-semibold">Players per Game</p>
                        <p class="title is-3 has-text-link"><ICountUp :endVal="averages.avgPlayers" /></p>
                    </div>
                </div>
                <div class="column is-one-fifth">
                    <div class="has-text-centered p-4">
                        <p class="heading has-text-weight-semibold">FF Damage</p>
                        <p class="title is-3 has-text-danger"><ICountUp :endVal="Math.round(averages.survivor_ff)" /> HP</p>
                    </div>
                </div>
                <div class="column is-one-fifth">
                    <div class="has-text-centered p-4">
                        <p class="heading has-text-weight-semibold">Ping</p>
                        <p class="title is-3 has-text-warning"><ICountUp :endVal="Math.round(averages.ping)" /> ms</p>
                    </div>
                </div>
            </div>
            <SummaryBit :values="averages" />
        </div>
        <!-- Map Statistics Section -->
        <div v-if="hasMapData" class="box has-background-success-light">
            <h2 class="title is-4 has-text-success has-text-centered mb-5">
                <span class="icon-text">
                    <span class="icon">
                        <i class="fas fa-map"></i>
                    </span>
                    <span>Map Statistics</span>
                </span>
            </h2>
            <div class="columns is-centered">
                <div v-if="averages.top_map" class="column is-half">
                    <div class="card">
                        <div class="card-content has-text-centered">
                            <p class="title is-5 has-text-success mb-4">Most Played Official Map</p>
                            <figure class="image is-4by3 mb-4">
                                <img :src="mostPlayedCampaignImage" class="is-rounded">
                            </figure>
                            <p class="title is-4 has-text-dark">{{getMapName(averages.top_map)}}</p>
                        </div>
                    </div>
                </div>
                <div v-if="averages.least_map" class="column is-half">
                    <div class="card">
                        <div class="card-content has-text-centered">
                            <p class="title is-5 has-text-warning mb-4">Least Played Official Map</p>
                            <figure class="image is-4by3 mb-4">
                                <img :src="leastPlayedCampaignImage" class="is-rounded">
                            </figure>
                            <p class="title is-4 has-text-dark">{{getMapName(averages.least_map)}}</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div v-if="mostPlayedDifficulty" class='has-text-centered'>
          <p><b>Most Played Difficulty:</b></p>
          <p>{{ mostPlayedDifficulty }}</p>
        </div>
    </div>
    <br><br>
</div>
</template>
<script>
import { getMapImage, getMapName } from '../js/map'
import SummaryBit from '../components/SummaryBit';
import ICountUp from 'vue-countup-v2';
import GameInfo from '../assets/gameinfo.json'
export default {
    data() {
        return {
            loading: true,
            averages: null,
            totals: null
        }
    },
    components: {
        SummaryBit,
        ICountUp
    },
    mounted() {
        Promise.all([
            this.fetchAverage(),
            this.fetchTotal()
        ]).finally(() => this.loading = false)
    },
    computed: {
        hasMapData() {
            return this.averages && (this.averages.top_map || this.averages.least_map);
        },
        mostPlayedDifficulty() {
            if(!this.averages || !this.averages.difficulty) return null;
            return GameInfo.difficulties[Number(this.averages.difficulty)]
        },
        mostPlayedCampaignImage() {
            return getMapImage(this.averages.top_map)
        },
        leastPlayedCampaignImage() {
            return getMapImage(this.averages.least_map)
        }
    },
    methods: {
        getMapName,
        fetchAverage() {
            this.loading = true;
            this.$http.get(`/api/summary`, { cache: true })
            .then(r => {
                this.averages = {
                    top_map: r.data.topMap,
                    least_map: r.data.bottomMap,
                    avgPlayers: r.data.averagePlayers,
                    ...r.data.stats
                }
            })
            .catch(err => {
                console.error('Fetch err', err)
                this.$buefy.snackbar.open({
                    duration: 5000,
                    message: 'Failed to fetch average values',
                    type: 'is-danger',
                    position: 'is-bottom-left',
                    actionText: 'Retry',
                    onAction: () => this.fetchAverage()
                })
            })
        },
        fetchTotal() {
            this.loading = true;
            this.$http.get(`/api/totals`, { cache: true })
            .then(r => {
                this.totals = r.data.stats

            })
            .catch(err => {
                console.error('Fetch err', err)
                this.$buefy.snackbar.open({
                    duration: 5000,
                    message: 'Failed to fetch total values',
                    type: 'is-danger',
                    position: 'is-bottom-left',
                    actionText: 'Retry',
                    onAction: () => this.fetchTotal()
                })
            })
        },
        formatNumber(number) {
            if(!number) return 0;
            return Math.round(number).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
        },
        colorizeJSON(obj) {
            const str = JSON.stringify(obj, null, 2).split("\n");
            const lines = [];
            for(const line of str) {
                const numberMatch = line.match(/(\d+\.?\d*),?$/);
                const strMatch = line.match(/("[0-9a-zA-Z_]+"),?$/);
                if(numberMatch && numberMatch.length > 0) {
                    lines.push(line.replace(/(\d+\.?\d*),?$/, `<span class='has-text-link'>${numberMatch[0]}</span>`))
                }else if(strMatch && strMatch.length > 0) {
                    lines.push(line.replace(/("[0-9a-zA-Z_]+"),?$/, `<span class='has-text-danger'>${strMatch[0]}</span>`))
                }else{
                    lines.push(line)
                }
            }
            return lines.join("\n");
        }
    }
}
</script>

<style>
img {
    object-fit: contain;
}
</style>
