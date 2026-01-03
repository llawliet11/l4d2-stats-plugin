<template>
<div>
    <section class="hero is-dark">
        <div class="hero-body">
            <div class="container has-text-centered">
            <h1 class="title">
                Campaigns
            </h1>
            <p class="subtitle">Sorted by most rated</p>
            </div>
        </div>
    </section>
    <br>
    <div class="container is-fluid">
      <div class="columns">
        <div class="column">
            <div class="table-container">
                <div class="table-wrapper">
                    <b-table
                        :loading="loading"
                        @click="onMapClick"
                        :data="maps"
                        :selected.sync="selected"
                        class="beautiful-table"
                        hoverable
                    >
                        <b-table-column field="map.name" label="Map" v-slot="props">
                            <router-link :to="'/maps/' + props.row.map.id">
                                <strong>{{ props.row.map.name }}</strong>
                            </router-link>
                        </b-table-column>
                        <b-table-column field="chapterCount" label="Chapters" centered v-slot="props">
                            {{ props.row.chapterCount }} chapters
                        </b-table-column>
                        <b-table-column field="uniquePlayers" label="Players" centered v-slot="props">
                            {{ props.row.uniquePlayers | formatNumber }}
                        </b-table-column>
                        <b-table-column field="totalKills" label="Total Kills" centered v-slot="props">
                            {{ props.row.totalKills | formatNumber }}
                        </b-table-column>
                        <b-table-column field="avgDuration" label="Avg Duration" centered v-slot="props">
                            {{ props.row.avgDuration | formatDuration }}
                        </b-table-column>
                    </b-table>
                </div>
            </div>
        </div>
      </div>
    </div>
</div>
</template>

<script>
export default {
    data() {
        return {
            maps: [],
            selected: null,
            loading: true
        }
    },
    methods: {
        fetchMaps() {
            this.loading = true;
            this.$http.get(`/api/maps`, { cache: true })
            .then(res => {
                this.maps = res.data;
            })
            .catch(err => {
                console.error('Fetch error', err)
                this.$buefy.snackbar.open({
                    duration: 5000,
                    message: 'Error occurred while fetching maps',
                    type: 'is-danger',
                    position: 'is-bottom-left',
                    actionText: 'Retry',
                    onAction: () => this.fetchMaps()
                })
            }).finally(() => this.loading = false)
        },
        onMapClick(row) {
            this.$router.push('/maps/' + row.map.id)
        }
    },
    mounted() {
        this.fetchMaps();
    },
    filters: {
        formatNumber(num) {
            if (num === null || num === undefined) return '0';
            return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
        },
        formatDuration(minutes) {
            if (!minutes) return 'minutes';
            const mins = parseFloat(minutes);
            if (mins < 60) return `${mins.toFixed(4)} minutes`;
            const hours = Math.floor(mins / 60);
            const remainingMins = Math.round(mins % 60);
            return `${hours}h ${remainingMins}m`;
        }
    }
}
</script>

<style>
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

.beautiful-table .table {
    margin-bottom: 0;
    border-radius: 0;
    background: white;
    width: 100%;
}

.beautiful-table .table thead th {
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

.beautiful-table .table tbody tr {
    transition: all 0.3s ease !important;
    border-bottom: 1px solid #f5f5f5 !important;
    cursor: pointer;
}

.beautiful-table .table tbody tr:hover {
    background: rgba(22, 125, 240, 0.05) !important;
}

.beautiful-table .table tbody tr:nth-child(even) {
    background-color: #fafafa !important;
}

.beautiful-table .table tbody tr:nth-child(even):hover {
    background: rgba(22, 125, 240, 0.08) !important;
}

.beautiful-table .table tbody tr.is-selected {
    background: rgba(22, 125, 240, 0.12) !important;
}

.beautiful-table .table tbody tr.is-selected:hover {
    background: rgba(22, 125, 240, 0.15) !important;
}

.beautiful-table .table td {
    vertical-align: middle !important;
    padding: 12px 10px !important;
    border: none !important;
    font-size: 0.9rem !important;
}

/* Map link styling */
.beautiful-table .table td a {
    color: #167df0 !important;
    text-decoration: none !important;
    font-weight: 500 !important;
    transition: all 0.3s ease !important;
}

.beautiful-table .table td a:hover {
    color: #1366d6 !important;
}
</style>
