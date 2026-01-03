<template>
<div>
    <section class="hero is-dark">
        <div class="hero-body">
            <div class="container has-text-centered">
            <h1 class="title">
                Top Played Maps
            </h1>
            </div>
        </div>
    </section>
    <br>
    <div class="container is-fluid">
      <div class="columns">
        <div class="column">
            <div class="table-container">
                <div class="table-wrapper">
                    <b-table :loading="loading" @select="onMapSelect" :data="maps" :selected.sync="selected" @details-open="onDetailsOpen" @details-close="details = null" class="beautiful-table">
                        <template slot-scope="props">
                            <b-table-column width="20" >
                                <router-link :to="getCampaignDetailLink(props.row.map_name)"><b-icon icon="angle-right" /></router-link>
                            </b-table-column>
                            <b-table-column field="map_name" label="Map" >
                                <router-link :to="getCampaignDetailLink(props.row.map_name)">
                                    <strong>{{ props.row.map_name | formatMap }}</strong>
                                </router-link>
                            </b-table-column>
                            <b-table-column field="wins" label="Wins" centered>
                                {{ props.row.wins | formatNumber }}
                            </b-table-column>
                            <b-table-column field="realism" label="Realism" centered>
                                {{ props.row.realism | formatNumber }}
                            </b-table-column>
                            <b-table-column field="realism" label="Easy" centered>
                                {{ props.row.difficulty_easy | formatNumber }}
                            </b-table-column>
                            <b-table-column field="realism" label="Normal" centered>
                                {{ props.row.difficulty_normal | formatNumber }}
                            </b-table-column>
                            <b-table-column field="realism" label="Advanced" centered>
                                {{ props.row.difficulty_advanced | formatNumber }}
                            </b-table-column>
                            <b-table-column field="realism" label="Expert" centered>
                                {{ props.row.difficulty_expert | formatNumber }}
                            </b-table-column>
                        </template>
                    </b-table>
                </div>
            </div>
        </div>
        <div v-if="selected" class="column is-4">
            <div class="box">
                <router-link :to="getCampaignDetailLink(selected.map_name)">
                <figure class="image is-4by5">
                    <img :src="mapUrl" />
                </figure>
                 </router-link>
                <b-button type="is-info" tag="router-link" size="is-large" expanded :to="getCampaignDetailLink(selected.map_name)">View</b-button>
            </div>
        </div>
      </div>
    </div>
</div>
</template>

<script>
import NoMapImage from '@/assets/no_map_image.png'
import { getMapName, getMapImage} from '../js/map'
export default {
    data() {
        return {
            maps: [],
            details: null,
            selected: null,
            loading: true
        }
    },
    methods: {
        fetchMaps() {
            this.loading = true;
            this.$http.get(`/api/maps`, { cache: true })
            .then(res => {
                this.maps = res.data.maps;
                if(this.$route.params.map) {
                    const map = this.maps.find(v => v.map_name.toLowerCase() == this.$route.params.map.toLowerCase())
                    if(map) {
                        this.selected = map;
                    }
                }
            })
            .catch(err => {
                console.error('Fetch error', err)
                this.$buefy.snackbar.open({
                    duration: 5000,
                    message: 'Error ocurred while fetching maps',
                    type: 'is-danger',
                    position: 'is-bottom-left',
                    actionText: 'Retry',
                    onAction: () => this.fetchMaps()
                })
            }).finally(() => this.loading = false)
        },
        onDetailsOpen(obj) {
            this.details = obj;
        },
        onMapSelect() {
            //this.$router.replace(`/maps/${sel.map_name}`)
        },
        getCampaignDetailLink(mapName) {
            const id = getMapName(mapName).toLowerCase().replace(/\s/, '-');
            return `/maps/${id}/details`
        }
    },
    watch: {
        '$route.params.map': function (oldv) {
            if(!oldv) {
                this.selected = null;
            }
        }
    },
    computed: {
        mapUrl() {
            if(this.selected) {
                const imageUrl = getMapImage(this.selected.map_name);
                return imageUrl ? `/img/posters/${imageUrl}` : NoMapImage;
            }
            return NoMapImage
        }
    },
    mounted() {
        this.fetchMaps();
    },
    filters: {
        formatMap(str) {
            return getMapName(str)
        },
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

.beautiful-table .button.is-info {
    background: #167df0 !important;
    border: none !important;
    color: white !important;
}

.beautiful-table .button.is-info:hover {
    background: #1366d6 !important;
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

.beautiful-table .table td .icon {
    color: #167df0 !important;
}

.beautiful-table .table td .icon:hover {
    color: #1366d6 !important;
}
</style>
