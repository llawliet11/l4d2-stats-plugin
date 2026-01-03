<template>
  <div>
    <section class="hero is-dark">
      <div class="hero-body">
        <div class="container has-text-centered">
          <h1 class="title">
            {{ mapInfo.name }}
          </h1>
          <p class="subtitle">
            {{ this.$route.params.id }}
          </p>
          <p class="subtitle" v-if="avgRating">
            <b-icon
              size="is-small"
              pack="fas"
              icon="star"
              v-for="i in Math.round(avgRating)"
              :key="i"
            />
            <b-icon
              size="is-small"
              pack="far"
              icon="star"
              v-for="i in 5 - Math.round(avgRating)"
              :key="i + 10"
            />
            {{ Number(avgRating).toFixed(1) }}
          </p>
        </div>
      </div>
    </section>
    <br />
    <div class="container is-fluid">
      <!-- Map Statistics Section -->
      <div class="columns" v-if="stats && stats.total_players > 0">
        <div class="column">
          <h4 class="title is-4">Map Statistics</h4>
          <nav class="level">
            <div class="level-item has-text-centered">
              <div>
                <p class="heading">Players</p>
                <p class="title">{{ stats.total_players | formatNumber }}</p>
              </div>
            </div>
            <div class="level-item has-text-centered">
              <div>
                <p class="heading">Zombies Killed</p>
                <p class="title">
                  {{ stats.total_zombies_killed | formatNumber }}
                </p>
              </div>
            </div>
            <div class="level-item has-text-centered">
              <div>
                <p class="heading">Specials Killed</p>
                <p class="title">
                  {{ stats.total_specials_killed | formatNumber }}
                </p>
              </div>
            </div>
            <div class="level-item has-text-centered">
              <div>
                <p class="heading">Deaths</p>
                <p class="title">{{ stats.total_deaths | formatNumber }}</p>
              </div>
            </div>
            <div class="level-item has-text-centered">
              <div>
                <p class="heading">Tanks Killed</p>
                <p class="title">
                  {{ stats.total_tanks_killed | formatNumber }}
                </p>
              </div>
            </div>
          </nav>

          <div class="buttons mt-4">
            <b-button
              type="is-primary"
              tag="router-link"
              :to="'/campaigns/map/' + $route.params.id"
              size="is-medium"
            >
              <b-icon icon="chart-bar" />
              <span>View Full Statistics</span>
            </b-button>
          </div>
        </div>
      </div>

      <!-- No Stats Message -->
      <div v-else class="has-text-centered py-6">
        <p class="is-size-5 has-text-grey">
          No player statistics available for this map yet.
        </p>
        <b-button
          type="is-primary"
          tag="router-link"
          :to="'/campaigns/map/' + $route.params.id"
          class="mt-4"
        >
          View Map Campaign Details
        </b-button>
      </div>

      <hr />

      <!-- Recent Players Section -->
      <div class="columns" v-if="recentPlayers && recentPlayers.length > 0">
        <div class="column">
          <h4 class="title is-4">Recent Players</h4>
          <div class="columns is-multiline">
            <div
              class="column is-3"
              v-for="player in recentPlayers"
              :key="player.steamid"
            >
              <div class="card">
                <div class="card-content">
                  <router-link
                    :to="'/user/' + player.steamid"
                    class="has-text-info"
                  >
                    <strong>{{ player.last_alias }}</strong>
                  </router-link>
                  <p class="is-size-7 has-text-grey">
                    {{ player.total_kills | formatNumber }} kills
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <hr />

      <!-- Ratings Section -->
      <div class="columns">
        <div class="column">
          <h4 class="title is-4">Ratings ({{ ratings.length }})</h4>
          <div
            class="columns is-multiline is-vcentered"
            v-if="ratings && ratings.length > 0"
          >
            <div class="column is-3" v-for="(rating, i) in ratings" :key="i">
              <div class="card">
                <div class="card-content">
                  <div class="media mb-0">
                    <div class="media-content">
                      <div class="columns">
                        <div class="column is-8">
                          <p class="title is-4">{{ rating.user.name }}</p>
                          <p class="subtitle is-6">{{ rating.user.id }}</p>
                        </div>
                        <div class="column is-4">
                          <b-icon
                            size="is-small"
                            pack="fas"
                            icon="star"
                            v-for="i in rating.value"
                            :key="i"
                          />
                          <b-icon
                            size="is-small"
                            pack="far"
                            icon="star"
                            v-for="i in 5 - rating.value"
                            :key="i + 10"
                          />
                        </div>
                      </div>
                    </div>
                  </div>
                  <article class="message my-2" v-if="rating.comment">
                    <div class="message-body py-2">
                      {{ rating.comment }}
                    </div>
                  </article>
                  <div class="block my-6" v-else></div>
                </div>
              </div>
            </div>
          </div>
          <p v-else class="has-text-grey">No ratings yet for this map.</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import NoMapImage from "@/assets/no_map_image.png";
import { getMapName, getMapImage } from "@/js/map";
export default {
  data() {
    return {
      mapInfo: { name: "Unknown" },
      ratings: [],
      avgRating: null,
      stats: null,
      recentPlayers: [],
      loading: true,
    };
  },
  methods: {
    async fetchDetails() {
      this.loading = true;
      this.$http
        .get(`/api/maps/${this.$route.params.id}`, { cache: true })
        .then((res) => {
          this.mapInfo = res.data.map;
          this.ratings = res.data.ratings;
          this.avgRating = res.data.avgRating;
          this.stats = res.data.stats;
          this.recentPlayers = res.data.recentPlayers || [];
        })
        .catch((err) => {
          console.error("Fetch error", err);
          this.$buefy.snackbar.open({
            duration: 5000,
            message: "Error ocurred while fetching maps",
            type: "is-danger",
            position: "is-bottom-left",
            actionText: "Retry",
            onAction: () => this.fetchDetails(),
          });
        })
        .finally(() => (this.loading = false));
    },
  },
  watch: {
    "$route.params.id": function () {
      this.fetchDetails();
    },
  },
  computed: {
    mapUrl() {
      if (this.selected) {
        const imageUrl = getMapImage(this.selected.map_name);
        return imageUrl ? `/img/posters/${imageUrl}` : NoMapImage;
      }
      return NoMapImage;
    },
  },
  mounted() {
    this.fetchDetails();
  },
  filters: {
    formatNumber(num) {
      if (num === null || num === undefined) return "0";
      return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    },
  },
};
</script>

<style scoped>
.level-item .title {
  color: #363636;
}
.card {
  height: 100%;
}
</style>
