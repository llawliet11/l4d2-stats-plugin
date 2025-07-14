<template>
<div>
    <section class="hero is-dark">
        <div class="hero-body">
            <div class="container has-text-centered">
            <h1 class="title">
                Player Statistics
            </h1>
            <p class="subtitle is-4"><b>{{total_sessions | formatNumber}}</b> active players</p>
            </div>
        </div>
    </section>
    <br>
    <div class="container is-fluid">
        <h5 class="title is-5">Sorted by Points (Overall MVP determined by MVP Points calculation)</h5>
        <div class="notification is-info">
            <h6 class="title is-6">MVP Points Calculation:</h6>
            <div class="columns">
                <div class="column">
                    <strong>Combat Actions:</strong>
                    <ul style="margin-left: 20px;">
                        <li>Special Infected Kills × 6</li>
                        <li>Common Kills × 1</li>
                        <li>Tank Kills × 100</li>
                        <li>Witch Kills × 15</li>
                        <li>Finales Won × 1000</li>
                    </ul>
                </div>
                <div class="column">
                    <strong>Teamwork & Items:</strong>
                    <ul style="margin-left: 20px;">
                        <li>Heals × 40</li>
                        <li>Revives × 25</li>
                        <li>Defibs × 30</li>
                        <li>Molotovs/Pipes/Bile × 5</li>
                        <li>Pills × 10, Adrenaline × 15</li>
                        <li>Damage Taken Bonus × 0.5</li>
                    </ul>
                </div>
                <div class="column">
                    <strong>Penalties:</strong>
                    <ul style="margin-left: 20px;">
                        <li>Teammate Kills × -100</li>
                        <li>Friendly Fire Damage × -2</li>
                    </ul>
                </div>
            </div>
        </div>
        <b-table
            :data="sessions"
            :loading="loading"

            paginated
            backend-pagination
            :current-page="current_page"
            per-page=12
            :total="total_sessions"
            @page-change="onPageChange"

        >
        <!-- TODO: background sort -->
                <b-table-column v-slot="props" label="View">
                    <b-button tag="router-link" :to="'/user/' + props.row.steamid" expanded type="is-info"> View Profile</b-button>
                </b-table-column>
                <b-table-column v-slot="props" field="steamid" label="User">
                    <router-link :to='"/user/" + props.row.steamid'>
                        <b>{{props.row.last_alias}}</b>
                        <span v-if="props.row.isMVP" class="mvp-badge">MVP</span>
                    </router-link>
                </b-table-column>
                <b-table-column v-slot="props" field="map" label="Map">
                    {{ getMapName(props.row.map) }}
                </b-table-column>
                <b-table-column v-slot="props" field="SpecialInfectedKills" label="Special Kills" centered cell-class="number-cell">
                    {{ props.row.SpecialInfectedKills | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" field="SurvivorFFCount" label="FF Count" centered cell-class="number-cell">
                    {{ props.row.SurvivorFFCount | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" field="ZombieKills" label="Zombie Kills" centered cell-class="number-cell">
                    {{ props.row.ZombieKills | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" field="DamageTaken" label="Damage Taken" centered cell-class="number-cell">
                    {{ props.row.DamageTaken | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" field="SurvivorDamage" label="Friendly Fire" centered cell-class="number-cell">
                    {{ props.row.SurvivorDamage | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" field="mvpPoints" label="MVP Points" centered cell-class="mvp-points-cell">
                    {{ props.row.mvpPoints | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" field="MedkitsUsed" label="Medkits Used" centered cell-class="number-cell">
                    {{ props.row.MedkitsUsed | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" label="Total Throwables" centered cell-class="number-cell">
                    {{ getThrowableCount(props.row) | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" label="Total Pills/Shots Used" centered cell-class="number-cell">
                    {{ getPillShotCount(props.row) | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" field="Incaps" label="Incaps" centered cell-class="number-cell">
                    {{ props.row.Incaps | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" field="Deaths" label="Deaths" centered cell-class="number-cell">
                    {{ props.row.Deaths | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" field="difficulty" label="Difficulty" centered>
                    {{ formatDifficulty(props.row.difficulty) }}
                </b-table-column>
            <template #detail="props">
              <pre>{{props.row}}</pre>
            </template>
            <template slot="empty">
                <section class="section">
                    <div class="content has-text-grey has-text-centered">
                        <p>There are no recorded sessions</p>
                    </div>
                </section>
            </template>
        </b-table>
    </div>
</div>
</template>

<script>
import { getMapName } from '../js/map'
export default {
    data() {
        return {
            sessions: [],
            loading: true,
            current_page: 1,
            total_sessions: 0
        }
    },
    mounted() {
        let routerPage = parseInt(this.$route.params.page);
        if(isNaN(routerPage) || routerPage <= 0) routerPage = 1;
        this.current_page = routerPage;
        this.fetchSessions()
        document.title = `Sessions - L4D2 Stats Plugin`
    },
    methods: {
        getMapName,
        fetchSessions() {
            this.loading = true;
            this.$http.get(`/api/sessions/?page=${this.current_page}&perPage=12`, { cache: true })
            .then(r => {
                this.sessions = r.data.sessions;
                this.total_sessions = r.data.total_sessions;
            })
            .catch(err => {
                console.error('Fetch err', err)
                this.$buefy.snackbar.open({
                    duration: 5000,
                    message: 'Failed to fetch game sessions.',
                    type: 'is-danger',
                    position: 'is-bottom-left',
                    actionText: 'Retry',
                    onAction: () => this.fetchSessions()
                })
            })
            .finally(() => this.loading = false)
        },
        onPageChange(page) {
            this.current_page = page;
            this.$router.replace({params: {page}})
            this.fetchSessions();
        },
        getThrowableCount(session) {
            return session.MolotovsUsed + session.PipebombsUsed + session.BoomerBilesUsed;
        },
        getPillShotCount(session) {
            return session.AdrenalinesUsed + session.PillsUsed
        },
        formatDifficulty(difficulty) {
            switch(difficulty) {
                case 0: return "Easy"
                case 1: return "Normal";
                case 2: return "Advanced"
                case 3: return "Expert"
            }
        },
        getRGB(campaignID) {
            if(!campaignID) return "#0f77ea"
            return "#" + dec2hex(campaignID.replace(/[^0-9]/g,'')).substring(0,6)
        }
    }
}
function dec2hex(str){ // .toString(16) only works up to 2^53
    var dec = str.toString().split(''), sum = [], hex = [], i, s
    while(dec.length){
        s = 1 * dec.shift()
        for(i = 0; s || i < sum.length; i++){
            s += (sum[i] || 0) * 10
            sum[i] = s % 16
            s = (s - sum[i]) / 16
        }
    }
    while(sum.length){
        hex.push(sum.pop().toString(16))
    }
    return hex.join('')
}
</script>
<style>
.number-cell {
  color: blue;
}
.table td {
    vertical-align: middle;;
}
.mvp-badge {
    background-color: #ffdd57;
    color: #363636;
    padding: 2px 6px;
    border-radius: 3px;
    font-size: 0.75rem;
    font-weight: bold;
    margin-left: 6px;
}
.mvp-points-cell {
    color: #23d160 !important;
    font-weight: bold;
}
</style>
