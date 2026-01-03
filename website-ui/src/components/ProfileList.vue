<template>
    <div class="table-container">
        <div class="table-wrapper">
            <b-table
                v-bind="$attrs"
                ref="profileList"
                class="has-text-left beautiful-table"

                @page-change="page => $emit('page-change', page)"
            >
          <b-table-column field="last_alias" label="Player Name" v-slot="props" >
              <b-tooltip label="Click to view their profile" position="is-right">
                  <router-link :to="getUserLink(props.row)" class="vcell">
                      <p><strong>{{ props.row.last_alias }}</strong></p>
                  </router-link>
              </b-tooltip>
          </b-table-column>
          <b-table-column field="points" label="Points" v-slot="props">
              <span class="points-cell">{{ Math.round(props.row.points) | formatNumber }}</span>
              <!-- <em> {{Math.round(props.row.points / (props.row.minutes_played / 60)) | formatNumber}} p/h</em> -->
          </b-table-column>
          <b-table-column label="Last Played" v-slot="props">
              {{ formatDateAndRel(props.row.last_join_date * 1000) }}
          </b-table-column>
          <b-table-column field="minutes_played" label="Total Playtime" v-slot="props">
              {{ humanReadable(props.row.minutes_played) }}
          </b-table-column>
        <template slot="empty">
            <section class="section">
                <div class="content has-text-grey has-text-centered" v-if="$attrs.search !== undefined">
                    <p>Could not find any recorded users matching your query.</p>
                    <br>
                    <b-button type="is-info" tag="router-link" to="/">Return Home</b-button>
                </div>
                <div class="content has-text-grey has-text-centered" v-else>
                    <p>Could not find any users.</p>
                </div>
            </section>
        </template>
            </b-table>
        </div>
    </div>
</template>


<script>
import { formatDuration, formatDistanceToNow } from 'date-fns'
export default {
  methods: {
    humanReadable(minutes) {
        let hours = Math.floor(minutes / 60);
        const days = Math.floor(hours / 24);
        minutes = minutes % 60;
        const day_text = days == 1 ? 'day' : 'days'
        const min_text = minutes == 1 ? 'minute' : 'minutes'
        const hour_text = hours == 1 ? 'hour' : 'hours'
        if(days >= 1) {
            hours = hours % 24;
            return `${days} ${day_text}, ${hours} ${hour_text}`
        }else if(hours >= 1) {
            return `${hours} ${hour_text}, ${minutes} ${min_text}`
        }else{
            return `${minutes} ${min_text}`
        }
    },
    formatMinutes(min) {
        return formatDuration({minutes: parseInt(min)})
    },
    getUserLink({steamid}) {
        return `/user/${steamid}`
    },
    formatDateAndRel(inp) {
        if(inp <= 0 || isNaN(inp)) return ""
        try {
            const rel = formatDistanceToNow(new Date(inp))
            return `${rel} ago`
        }catch(err) {
            return ""
        }
    },
  }
}
</script>


<style scoped>
.valign {
  vertical-align: middle;
}

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

/* When table has pagination, adjust the wrapper */
.beautiful-table .table-wrapper {
    border-bottom-left-radius: 0;
    border-bottom-right-radius: 0;
    border-bottom: none;
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
    background: #167df0;
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
    background: rgba(22, 125, 240, 0.05);
}

.beautiful-table .table tbody tr:nth-child(even) {
    background-color: #fafafa;
}

.beautiful-table .table tbody tr:nth-child(even):hover {
    background: rgba(22, 125, 240, 0.08);
}

.beautiful-table .table td {
    vertical-align: middle;
    padding: 12px 10px;
    border: none;
    font-size: 0.9rem;
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

/* Override Buefy table pagination positioning */
.beautiful-table .b-table .table-wrapper {
    border-bottom-left-radius: 0;
    border-bottom-right-radius: 0;
}

.beautiful-table .b-table .pagination-wrapper {
    background: white;
    padding: 15px 20px;
    border-top: 1px solid #f5f5f5;
    border-bottom-left-radius: 4px;
    border-bottom-right-radius: 4px;
    display: flex;
    justify-content: center;
    margin: 0;
}

.beautiful-table .pagination-link,
.beautiful-table .pagination-previous,
.beautiful-table .pagination-next {
    background: #167df0 !important;
    border-color: #167df0 !important;
    color: white !important;
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
}

.points-cell {
    color: #167df0 !important;
    font-weight: 600;
    font-family: 'Monaco', 'Menlo', monospace;
    font-size: 1rem;
}
</style>
