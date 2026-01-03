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
        <b-table :loading="loading" :data="ratings" hoverable>
            <b-table-column v-slot="props" field="map.name" label="Map">
              <router-link :to="getCampaignDetailLink(props.row.map.id)">
                <strong>{{ props.row.map.name || props.row.map.id }}</strong>
              </router-link>
            </b-table-column>
            <b-table-column v-slot="props" field="chapterCount" label="Chapters" centered>
                {{ props.row.chapterCount }} chapters
            </b-table-column>
            <b-table-column v-slot="props" field="uniquePlayers" label="Players" centered>
                {{ props.row.uniquePlayers | formatNumber }}
            </b-table-column>
            <b-table-column v-slot="props" field="totalKills" label="Total Kills" centered>
                {{ props.row.totalKills | formatNumber }}
            </b-table-column>
        </b-table>
      </div>
    </div>
  </div>
</div>
</template>

<script>
import NoMapImage from '@/assets/no_map_image.png'
import { getMapName, getMapImage} from '@/js/map'
export default {
    data() {
        return {
            ratings: [],
            loading: true
        }
    },
    methods: {
        async fetchMaps() {
            this.loading = true;
            this.$http.get(`/api/maps`, { cache: true })
            .then(res => {
                this.ratings = res.data
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
        getCampaignDetailLink(mapId) {
            return `/maps/${mapId}`
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
        formatNumber(num) {
            if (num === null || num === undefined) return '0';
            return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
        },
        formatDuration(minutes) {
            if (!minutes) return '-';
            const mins = parseFloat(minutes);
            if (mins < 60) return `${Math.round(mins)} min`;
            const hours = Math.floor(mins / 60);
            const remainingMins = Math.round(mins % 60);
            return `${hours}h ${remainingMins}m`;
        }
    }
}
</script>
