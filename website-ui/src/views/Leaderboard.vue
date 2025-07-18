<template>
  <div class="home">
    <section class="hero is-dark">
      <div class="hero-body">
        <div class="container has-text-centered">
          <h1 class="title" >
            Leaderboards
          </h1>
          <h2 class="subtitle">
            <p>Showing the top <strong>{{top_today.length}}</strong> players out of <strong>{{players_total | formatNumber}}</strong> unique total players</p>
          </h2>
        </div>
      </div>
    </section>
    <br>
    <div class="container is-fluid">
      <div class="columns">
        <div class="column">
          <ProfileList
            height="100%"
            :data="top_today"
            :loading="loading"

            striped sticky-header
            paginated
            backend-pagination
            :current-page="top_page"
            per-page=15
            :total="players_total"

            @page-change="onTopPageChange"
          />
        </div>
        <div class="column is-3">
          <div class="box">
            <form @submit.prevent="searchUser">
            <b-field label="Enter Username or Steam ID">
              <b-field>
                <b-input v-model="search" placeholder="STEAM_1:0:49243767"  icon="search">
                </b-input>
                <p class="control">
                  <input type="submit" class="button is-info" value="Search"/>
                </p>
              </b-field>
            </b-field>
            </form>
          </div>
          <!--<div class="box">
            <h5 class='title is-5'>Categories</h5>
            <b-menu-list>
              <b-menu-item label="Top Overall"></b-menu-item>
              <b-menu-item label="Top Campaign"></b-menu-item>
              <b-menu-item label="Top Versus"></b-menu-item>
              <b-menu-item label="Top Survival"></b-menu-item>
              <b-menu-item label="Top Scavenge"></b-menu-item>
            </b-menu-list>
          </div>-->
          <div class="box">
            <b-carousel :interval="60000" :pause-info="false" :arrow="false" v-if="!stats.loading&&stats.data != null">
              <b-carousel-item v-for="stat in $options.STATS" :key="stat">
                  <section :class="`hero is-medium is-a`">
                      <div class="hero-body has-text-centered px-0">
                          <h6 class="title is-6">{{$options.STAT_DISPLAY_NAMES[stat]}}</h6>
                          <ol style="text-align: left !important">
                            <li v-for="player in stats.data[stat]" :key="player.steamid">
                              <router-link :to="'/user/' + player.steamid" class="has-text-info has-text-weight-bold">
                                {{player.last_alias}}
                              </router-link>
                              <span>: {{player.value | formatNumber}} {{$options.STAT_VALUE_NAMES[stat]}}</span>
                            </li>
                          </ol>
                      </div>
                  </section>
              </b-carousel-item>
            </b-carousel>
            <p v-else>Loading</p>
          </div>
          <div class="box has-text-centered" v-if="randomPlayer">
            <h6 class="title is-6">Random Player of the Day</h6>
            <router-link :to="'/user/' + randomPlayer.steamid + '/overview'" class="title">{{randomPlayer.last_alias}}</router-link>
            <br>
            <p class="subtitle is-6"><em>{{Math.round(randomPlayer.points) | formatNumber}} points</em></p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
// @ is an alias to /src
import ProfileList from '@/components/ProfileList'
export default {
  name: 'Leaderboard',
  components: {
    ProfileList
  },
  STATS: [ 'clownHonks', 'deaths', 'ffDamage', 'healOthers', 'revivedOthers', 'survivorIncaps', 'timesMVP'],
  STAT_DISPLAY_NAMES: {
    deaths: 'Most Deaths',
    ffDamage: 'Most Friendly Fire Damage',
    healOthers: 'Healed the Most Players',
    revivedOthers: 'Revived the Most Players',
    survivorIncaps: 'Most Incaps',
    clownHonks: 'Most Clown Honks',
    timesMVP: 'Most Times MVP'
  },
  STAT_VALUE_NAMES: {
    deaths: 'deaths',
    ffDamage: 'HP',
    healOthers: 'heals',
    revivedOthers: 'revives',
    survivorIncaps: 'incaps',
    clownHonks: 'clowns honked',
    timesMVP: 'times'
  },
  data() {
    return {
      top_today: [],
      top_page: 1,
      failure: false,
      players_total: 0,
      search: '',
      loading: true,
      stats: {
        loading: true,
        data: null
      },
      randomPlayer: null
    }
  },
  mounted() {
    let currentRoutePage = !isNaN(this.$route.params.page) ? parseInt(this.$route.params.page) : 0
    if(currentRoutePage <= 0) currentRoutePage = 1;
    this.top_page = currentRoutePage;
    Promise.all([
      this.refreshInfo(),
      this.refreshTop(),
    ]).then(() => {
      this.refreshStats()
      this.refreshRandom()
    })
  },
  methods: {
    refreshInfo() {
      return this.$http.get(`/api/info`, { cache: true })
      .then((r) => {
        this.players_total = r.data.total_users;
      })
      .catch(err => {
        this.failure = true;
        console.error('Fetch error', err)
        this.$buefy.snackbar.open({
            duration: 5000,
            message: 'Error ocurred while fetching leaderboard information',
            type: 'is-danger',
            position: 'is-bottom-left',
            actionText: 'Retry',
            onAction: () => this.refreshInfo()
        })
      }).finally(() => this.loading = false)
    },
    refreshTop() {
      console.debug('Loading users for page' + this.top_page)
      this.loading = true;
      const params = this.$route.query.version ? `?version=${this.$route.query.version}` : ""
      return this.$http.get(`/api/top/users/${this.top_page}${params}`, { cache: true })
      .then((r) => {
        this.top_today = r.data.users;
      })
      .catch(err => {
        this.failure = true;
        console.error('Fetch error', err)
        this.$buefy.snackbar.open({
            duration: 5000,
            message: 'Error ocurred while fetching top players for today.',
            type: 'is-danger',
            position: 'is-bottom-left',
            actionText: 'Retry',
            onAction: () => this.refreshTop()
        })
      }).finally(() => this.loading = false)
    },
    refreshStats() {
      const stats = window.localStorage.getItem('l4d2_stats_topstats');
      if(stats) {
        const json = JSON.parse(stats);
        if(Date.now() - json.timestamp <= 1000 * 60 * 60 * 24) {
          this.stats.loading = false;
          this.stats.data = json.stats;
          return;
        }
      }
      this.$http.get(`/api/top/stats`, { cache: true })
      .then((r) => {
        this.stats.data = r.data;

      })
      .catch(err => {
        console.error('Fetch stats failed. ', err)
      })
      .finally(() => this.stats.loading = false)
    },
    refreshRandom() {
      return this.$http.get(`/api/user/random`, { cache: true })
      .then((r) => {
        this.randomPlayer = r.data.user
      })
      .catch(() => {
        console.warn('Could not fetch random player')
      }).finally(() => this.loading = false)
    },
    onTopPageChange(page) {
      this.top_page = page;
      this.$router.replace(`/top/${page}`)
        this.refreshTop();

    },
    searchUser() {
      if(this.search.trim().length > 0)
        this.$router.push(`/search/${this.search.trim()}`)
    }
  },
  metaInfo: [
    { name: 'og:title', content: "Leaderboards - L4D2 Stats Plugin"}
  ]
}
</script>

<style>
.hero.is-medium .hero-body {
  padding-top: 0 !important;
  padding-bottom: 40px !important;
}
.carousel .carousel-indicator .indicator-item .indicator-style.is-dots {
  height: 15px !important;
  width: 15px !important;
}

/* Override carousel indicator colors */
.carousel .carousel-indicator .indicator-item .indicator-style.is-dots {
  background-color: #167df0 !important;
}

.carousel .carousel-indicator .indicator-item:not(.is-active) .indicator-style.is-dots {
  background-color: rgba(22, 125, 240, 0.3) !important;
}
/* Leaderboard pagination styling */
.pagination {
  margin-right: 10px;
}

/* Style pagination in the leaderboard table */
.beautiful-table .pagination-wrapper {
  background: white;
  padding: 15px 20px;
  border-top: 1px solid #f5f5f5;
  border-bottom-left-radius: 4px;
  border-bottom-right-radius: 4px;
  display: flex;
  justify-content: center;
  margin: 0 ;
  border: 1px solid #e0e0e0;
  border-top: none;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

/* Center pagination specifically for leaderboard */
.beautiful-table .pagination {
  justify-content: center !important;
  margin: 0 10px 0 0 !important;
}

/* Blue pagination buttons */
.beautiful-table .pagination-link,
.beautiful-table .pagination-previous,
.beautiful-table .pagination-next {
  background: #167df0 !important;
  border-color: #167df0 !important;
  color: white !important;
  border-radius: 4px !important;
}

.beautiful-table .pagination-link:hover,
.beautiful-table .pagination-previous:hover,
.beautiful-table .pagination-next:hover {
  background: #1366d6 !important;
  border-color: #1366d6 !important;
  color: white !important;
}

.beautiful-table .pagination-link.is-current {
  background: #1366d6 !important;
  border-color: #1366d6 !important;
  color: white !important;
}
</style>
