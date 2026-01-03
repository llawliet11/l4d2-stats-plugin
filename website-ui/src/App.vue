<template>
  <div id="app">
    <b-navbar fixed-top>
        <template slot="brand">
            <b-navbar-item tag="router-link" to="/">
                <h5 class="title is-5">{{title}}</h5>
            </b-navbar-item>
        </template>
        <template slot="start">
            <b-navbar-item  tag="router-link" to="/top">
                Leaderboards
            </b-navbar-item>
            <!-- <b-navbar-item tag="router-link" to="/maps">
                Maps List
            </b-navbar-item> -->
            <b-navbar-item tag="router-link" to="/summary">
                Summary
            </b-navbar-item>
            <b-navbar-item tag="router-link" to="/maps">
                Campaigns
            </b-navbar-item>
            <b-navbar-item tag="router-link" to="/campaigns">
                Games
            </b-navbar-item>
            <b-navbar-item tag="router-link" to="/sessions">
                Sessions
            </b-navbar-item>
            <b-navbar-item tag="router-link" to="/faq">
                About & FAQ
            </b-navbar-item>
        </template>

        <template slot="end">
            <b-navbar-item>
              <b-button
                type="is-warning"
                size="is-small"
                @click="recalculatePoints"
                :loading="recalculating"
              >
                Quick Recalculate
              </b-button>
            </b-navbar-item>
            <b-navbar-item>
              <b-button
                type="is-primary"
                size="is-small"
                @click="showAdvancedRecalculate"
                :disabled="recalculating"
              >
                Advanced
              </b-button>
            </b-navbar-item>
            <b-navbar-item>
              <form @submit.prevent="searchUser">
              <b-field>
                  <b-autocomplete
                    v-debounce:400ms="onSearchAutocomplete"
                    v-model="search.query"
                    placeholder="Search for a user..."
                    icon="search"
                    :data="search.autocomplete"
                    clearable
                    field="last_alias"
                    @select="onSearchSelect"
                    @enter.native="searchUser"
                    clear-on-select
                    expanded
                    :loading="search.loading"
                    >
                    <template v-slot:empty>No users were found</template>
                    <template  v-slot:default="props">
                      <b>{{props.option.last_alias}}</b> ({{props.option.steamid}})
                    </template>
                  </b-autocomplete>
                <p class="control">
                  <input type="submit" class="button is-info" value="Search"/>
                </p>
              </b-field>
              </form>
            </b-navbar-item>
        </template>
    </b-navbar>
    <keep-alive :max="5">
      <router-view :key="$route.fullPath" />
    </keep-alive>
  </div>
</template>

<script>
import RecalculateModal from './components/admin/RecalculateModal.vue'

export default {
  components: {
    RecalculateModal
  },
  computed: {
    title() {
      return process.env.VUE_APP_SITE_NAME
    },
    version() {
      return `v${process.env.VUE_APP_VERSION}`
    }
  },
  data() {
    return {
      search: {
        query: null,
        last_autocomplete: null,
        autocomplete: [],
        loading: false
      },
      recalculating: false
    }
  },
  methods: {
    searchUser() {
      const query = this.search.query.trim();
      if(query.length == 0) return;
      if(this.$route.name === "Search") {
        this.$router.replace(`/search/${query}`)
      }else{
        this.$router.push(`/search/${query}`)
      }
    },
    onSearchAutocomplete() {
      this.loading = true;
      const query = this.search.query.trim();
      if(query.length == 0 || this.search.last_autocomplete == query) return;
      this.$http.get(`/api/search/${query}`,{cache:true})
      .then(res => {
          this.search.autocomplete = res.data;
          this.search.last_autocomplete = query;
      })
      .catch(err => {
          console.error('Failed to fetch autocomplete results', err)
      })
      .finally(() => this.loading = false)
    },
    onSearchSelect(obj) {
      if(obj) {
        this.$router.push('/user/' + obj.steamid)
      }
    },
    recalculatePoints() {
      this.$buefy.dialog.confirm({
        title: 'Recalculate Points',
        message: 'This will recalculate all user points based on the current scoring rules. This process may take several minutes and will clear existing point history. Are you sure you want to continue?',
        confirmText: 'Recalculate',
        type: 'is-warning',
        hasIcon: false,
        onConfirm: () => this.performRecalculation()
      })
    },
    async performRecalculation() {
      this.recalculating = true
      try {
        const response = await this.$http.post('/api/recalculate')

        if (response.data.success) {
          const stats = response.data.stats;
          this.$buefy.toast.open({
            duration: 8000,
            message: `Points recalculated successfully!
            Overall: ${stats.users_processed} users processed, ${stats.total_points_calculated} total points.
            Maps: ${stats.map_users_processed} map-user combinations processed, ${stats.total_map_points_calculated} total map points.`,
            type: 'is-success'
          })

          // Force refresh current page to show updated points
          this.$router.go(0)
        } else {
          throw new Error(response.data.message || 'Recalculation failed')
        }
      } catch (error) {
        console.error('Recalculation error:', error)
        this.$buefy.toast.open({
          duration: 8000,
          message: `Failed to recalculate points: ${error.response?.data?.message || error.message}`,
          type: 'is-danger'
        })
      } finally {
        this.recalculating = false
      }
    },
    showAdvancedRecalculate() {
      this.$buefy.modal.open({
        parent: this,
        component: RecalculateModal,
        hasModalCard: true,
        customClass: 'custom-modal',
        trapFocus: true,
        events: {
          success: (result) => {
            console.log('Advanced recalculation completed:', result)
          }
        }
      })
    }
  }
}


</script>

<style>
/* Global background color */
:root {
  background-color: #b8b8b8;
}

html, body {
  background-color: #b8b8b8;
  min-height: 100vh;
}

#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  color: #2c3e50;
  background-color: #b8b8b8;
  min-height: 100vh;
}

/* Header/Navbar styling */
.navbar {
  background-color: #167df0 !important;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.navbar-brand .navbar-item,
.navbar-start .navbar-item,
.navbar-end .navbar-item {
  color: white !important;
  transition: all 0.2s ease;
}

.navbar-brand .navbar-item:hover,
.navbar-start .navbar-item:hover,
.navbar-end .navbar-item:hover {
  background-color: #1366d6 !important;
  color: white !important;
}

/* Fix focus state - remove white background on click */
.navbar-brand .navbar-item:focus,
.navbar-start .navbar-item:focus,
.navbar-end .navbar-item:focus {
  background-color: #1366d6 !important;
  color: white !important;
  outline: none !important;
}

/* Active state for current route */
.navbar-brand .navbar-item.is-active,
.navbar-start .navbar-item.is-active,
.navbar-end .navbar-item.is-active {
  background-color: #0f5bb8 !important;
  color: white !important;
  font-weight: 600 !important;
}

/* Exact active state for current route */
.navbar-brand .navbar-item.router-link-exact-active,
.navbar-start .navbar-item.router-link-exact-active,
.navbar-end .navbar-item.router-link-exact-active {
  background-color: #0f5bb8 !important;
  color: white !important;
  font-weight: 600 !important;
}

.navbar-brand .title {
  color: white !important;
}

/* Search button styling */
.navbar .button.is-info {
  background-color: #1366d6;
  border-color: #1366d6;
}

.navbar .button.is-info:hover {
  background-color: #0f5bb8;
  border-color: #0f5bb8;
}

/* Override Buefy navbar item default focus/active states */
.navbar-item:focus,
.navbar-item:focus-within,
.navbar-item:active {
  background-color: transparent !important;
  color: inherit !important;
}

/* Ensure navbar items in navbar context override Buefy defaults */
.navbar .navbar-item:focus,
.navbar .navbar-item:focus-within,
.navbar .navbar-item:active {
  background-color: #1366d6 !important;
  color: white !important;
}

#nav {
  padding: 30px;
}

#nav a {
  font-weight: bold;
  color: #2c3e50;
}

#nav a.router-link-exact-active {
  color: #42b983;
}

/* Global pagination overrides */
.pagination-link.is-current {
  background-color: #167df0 !important;
  border-color: #167df0 !important;
  color: white !important;
}

.pagination-link:hover {
  background-color: #1366d6 !important;
  border-color: #1366d6 !important;
  color: white !important;
}

.pagination-link:focus {
  background-color: #1366d6 !important;
  border-color: #1366d6 !important;
}

/* Global table header styling */
.table thead th {
  background-color: #167df0 !important;
  color: white !important;
  border: none !important;
  padding: 15px 10px !important;
  font-weight: 600 !important;
  text-transform: uppercase !important;
  font-size: 0.85rem !important;
  letter-spacing: 0.5px !important;
}

/* Beautiful table styling */
.beautiful-table .table thead th {
  background-color: #167df0 !important;
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

/* Buefy table header styling */
.b-table .table thead th {
  background-color: #167df0 !important;
  color: white !important;
  border: none !important;
  padding: 15px 10px !important;
  font-weight: 600 !important;
  text-transform: uppercase !important;
  font-size: 0.85rem !important;
  letter-spacing: 0.5px !important;
}
</style>
