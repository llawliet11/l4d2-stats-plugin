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

        <!-- Beautiful Scrollable Table Container -->
        <div class="table-container">
            <div class="table-wrapper">
                <b-table
                    :data="sessions"
                    :loading="loading"
                    paginated
                    backend-pagination
                    :current-page="current_page"
                    per-page=12
                    :total="total_sessions"
                    @page-change="onPageChange"
                    :mobile-cards="false"
                    class="beautiful-table"
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
                <b-table-column v-slot="props" field="special_infected_kills" label="Special Kills" centered cell-class="number-cell">
                    {{ props.row.special_infected_kills | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" field="survivor_ff_count" label="FF Count" centered cell-class="number-cell">
                    {{ props.row.survivor_ff_count | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" field="common_kills" label="Zombie Kills" centered cell-class="number-cell">
                    {{ props.row.common_kills | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" field="survivor_damage_rec" label="Damage Taken" centered cell-class="number-cell">
                    {{ props.row.survivor_damage_rec | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" field="survivor_ff" label="Friendly Fire" centered cell-class="number-cell">
                    {{ props.row.survivor_ff | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" field="survivor_ff_rec" label="Friendly Fire Received" centered cell-class="number-cell">
                    {{ props.row.survivor_ff_rec | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" field="mvpPoints" label="MVP Points" centered cell-class="mvp-points-cell">
                    {{ props.row.mvpPoints | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" field="heal_others" label="Medkits Used" centered cell-class="number-cell">
                    {{ props.row.heal_others | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" label="Total Throwables" centered cell-class="number-cell">
                    {{ getThrowableCount(props.row) | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" label="Total Pills/Shots Used" centered cell-class="number-cell">
                    {{ getPillShotCount(props.row) | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" field="survivor_incaps" label="Incaps" centered cell-class="number-cell">
                    {{ props.row.survivor_incaps | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" field="survivor_deaths" label="Deaths" centered cell-class="number-cell">
                    {{ props.row.survivor_deaths | formatNumber }}
                </b-table-column>
                <b-table-column v-slot="props" field="difficulty" label="Difficulty" centered>
                    {{ (props.row.difficulty) }}
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
            return session.throws_molotov + session.throws_pipe + session.throws_puke;
        },
        getPillShotCount(session) {
            return session.adrenaline_used + session.pills_used
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
/* Beautiful Scrollable Table Styles */
.table-container {
    background: #167df0;
    border-radius: 4px;
    padding: 5px;
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
    margin: 10px 0;
}

.table-wrapper {
    background: white;
    border-radius: 4px;
    overflow: auto;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
    max-height: 80vh;
    position: relative;
    /* Enable both horizontal and vertical scrolling */
    overflow-x: auto;
    overflow-y: auto;
}

/* Horizontal scrollbar */
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

/* Corner where scrollbars meet */
.table-wrapper::-webkit-scrollbar-corner {
    background: #f1f1f1;
}

.beautiful-table {
    margin-bottom: 0 !important;
}

.beautiful-table .table {
    margin-bottom: 0;
    border-radius: 0;
    background: white;
    min-width: 1200px; /* Force horizontal scroll on smaller screens */
    width: 100%;
}

.beautiful-table .table thead th {
    background: #1366d6;
    color: white;
    border: none;
    padding: 15px 10px;
    font-weight: 600;
    text-transform: uppercase;
    font-size: 0.85rem;
    letter-spacing: 0.5px;
    position: sticky;
    top: 0;
    z-index: 10;
}

.beautiful-table .table tbody tr {
    transition: all 0.3s ease;
    border-bottom: 1px solid #f5f5f5;
}

.beautiful-table .table tbody tr:hover {
    background: rgba(22, 125, 240, 0.08);
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}

.beautiful-table .table tbody tr:nth-child(even) {
    background-color: #fafafa;
}

.beautiful-table .table tbody tr:nth-child(even):hover {
    background: rgba(22, 125, 240, 0.12);
}

.beautiful-table .table td {
    vertical-align: middle;
    padding: 12px 10px;
    border: none;
    font-size: 0.9rem;
}

.number-cell {
    color: #167df0 !important;
    font-weight: 600;
    font-family: 'Monaco', 'Menlo', monospace;
}

.mvp-badge {
    background: #ffd700;
    color: #2c3e50;
    padding: 4px 8px;
    border-radius: 4px;
    font-size: 0.7rem;
    font-weight: bold;
    margin-left: 8px;
    box-shadow: 0 2px 8px rgba(255, 215, 0, 0.3);
    text-transform: uppercase;
    letter-spacing: 0.5px;
}

.mvp-points-cell {
    color: #27ae60 !important;
    font-weight: bold;
    font-size: 1rem;
    text-shadow: 0 1px 2px rgba(39, 174, 96, 0.2);
}

.beautiful-table .pagination-wrapper {
    background: white;
    padding: 15px 20px;
    border-top: 1px solid #f5f5f5;
    display: flex;
    justify-content: center;
    margin-right: 15px;
}

.beautiful-table .pagination {
    justify-content: center !important;
}

/* Force center pagination with higher specificity */
.beautiful-table .b-table .pagination,
.beautiful-table .table-wrapper + .pagination,
.beautiful-table .pagination-wrapper .pagination {
    justify-content: center !important;
    margin: 0 auto !important;
    width: 100% !important;
    display: flex !important;
}

/* Blue pagination styling */
.beautiful-table .pagination-link,
.beautiful-table .pagination-previous,
.beautiful-table .pagination-next {
    background: #167df0;
    border-color: #167df0;
    color: white;
}

.beautiful-table .pagination-link:hover,
.beautiful-table .pagination-previous:hover,
.beautiful-table .pagination-next:hover {
    background: #1366d6;
    border-color: #1366d6;
    color: white;
}

.beautiful-table .pagination-link.is-current {
    background: #1366d6;
    border-color: #1366d6;
    color: white;
}

.beautiful-table .b-table .table-wrapper .pagination-wrapper {
    display: flex;
    justify-content: center;
}

.beautiful-table .button {
    border-radius: 4px;
    font-weight: 500;
    transition: all 0.3s ease;
}

.beautiful-table .button.is-info {
    background: #167df0;
    border: none;
    color: white;
}

.beautiful-table .button.is-info:hover {
    background: #1366d6;
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(22, 125, 240, 0.3);
}

/* Scroll indicators */
.table-wrapper::before {
    content: '';
    position: absolute;
    top: 0;
    right: 0;
    width: 20px;
    height: 100%;
    background: linear-gradient(to left, rgba(255,255,255,0.8), transparent);
    pointer-events: none;
    z-index: 5;
}

.table-wrapper::after {
    content: '';
    position: absolute;
    bottom: 10px;
    right: 20px;
    background: rgba(22, 125, 240, 0.9);
    color: white;
    padding: 4px 8px;
    border-radius: 4px;
    font-size: 0.75rem;
    opacity: 0.7;
    pointer-events: none;
    z-index: 5;
}

/* Responsive adjustments */
@media (max-width: 768px) {
    .table-container {
        padding: 10px;
        margin: 10px 0;
    }

    .table-wrapper {
        max-height: 70vh;
    }

    .beautiful-table .table {
        min-width: 800px; /* Smaller min-width for mobile */
    }

    .beautiful-table .table thead th {
        padding: 8px 6px;
        font-size: 0.75rem;
        white-space: nowrap;
    }

    .beautiful-table .table td {
        padding: 8px 6px;
        font-size: 0.8rem;
        white-space: nowrap;
    }

    .table-wrapper::after {
        content: 'Swipe →';
        bottom: 5px;
        right: 10px;
        font-size: 0.7rem;
    }
}

/* Loading state styling */
.beautiful-table .loading-overlay {
    background: rgba(255, 255, 255, 0.95);
    backdrop-filter: blur(4px);
}
</style>
