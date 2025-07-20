<template>
  <div class="modal-card" style="width: auto">
    <header class="modal-card-head">
      <p class="modal-card-title">Advanced Point Recalculation</p>
    </header>
    <section class="modal-card-body">
      <div class="field">
        <label class="label">Recalculation Mode</label>
        <div class="control">
          <label class="radio">
            <input type="radio" v-model="options.mode" value="full">
            Full Recalculation (Stats + Transactions)
          </label>
        </div>
        <div class="control">
          <label class="radio">
            <input type="radio" v-model="options.mode" value="stats_only">
            Stats Only (Traditional)
          </label>
        </div>
        <div class="control">
          <label class="radio">
            <input type="radio" v-model="options.mode" value="transactions_only">
            Transactions Only
          </label>
        </div>
      </div>

      <div class="field" v-if="options.mode === 'full' || options.mode === 'transactions_only'">
        <label class="checkbox">
          <input type="checkbox" v-model="options.update_transactions">
          Update Point Transaction Amounts
        </label>
        <p class="help">Recalculate individual point transaction amounts based on current point-system.json rules</p>
      </div>

      <div class="field" v-if="options.update_transactions">
        <label class="checkbox">
          <input type="checkbox" v-model="options.backup_original">
          Backup Original Amounts
        </label>
        <p class="help">Save original amounts before updating (recommended for first-time use)</p>
      </div>

      <div class="field" v-if="options.update_transactions">
        <label class="checkbox">
          <input type="checkbox" v-model="options.force_version_update">
          Force Version Update for All Transactions
        </label>
        <p class="help">Update calculation_version even for transactions with unchanged amounts (ensures consistency)</p>
      </div>

      <div class="field">
        <label class="label">User Filter (Optional)</label>
        <div class="control">
          <input 
            class="input" 
            type="text" 
            v-model="options.user_filter" 
            placeholder="STEAM_1:0:123456 (leave empty for all users)"
          >
        </div>
        <p class="help">Limit recalculation to specific user (useful for testing)</p>
      </div>

      <div class="field">
        <label class="checkbox">
          <input type="checkbox" v-model="options.dry_run">
          Dry Run (Preview Only)
        </label>
        <p class="help">Preview changes without actually updating the database</p>
      </div>

      <div class="notification is-warning" v-if="options.update_transactions && !options.dry_run">
        <strong>Warning:</strong> This will modify point transaction amounts in the database. 
        Make sure you have a backup before proceeding.
      </div>

      <div class="notification is-info" v-if="options.dry_run">
        <strong>Dry Run Mode:</strong> No changes will be made to the database. 
        This will only show you what would be changed.
      </div>
    </section>
    <footer class="modal-card-foot">
      <button 
        class="button is-primary" 
        @click="performRecalculation"
        :class="{ 'is-loading': loading }"
        :disabled="loading"
      >
        {{ options.dry_run ? 'Preview Changes' : 'Start Recalculation' }}
      </button>
      <button class="button" @click="$emit('close')" :disabled="loading">Cancel</button>
    </footer>
  </div>
</template>

<script>
export default {
  name: 'RecalculateModal',
  data() {
    return {
      loading: false,
      options: {
        mode: 'full',
        update_transactions: true,
        backup_original: true,
        user_filter: '',
        dry_run: false,
        force_version_update: true
      }
    }
  },
  methods: {
    async performRecalculation() {
      this.loading = true
      try {
        // Prepare request payload
        const payload = {
          mode: this.options.mode,
          update_transactions: this.options.update_transactions,
          backup_original: this.options.backup_original,
          dry_run: this.options.dry_run,
          force_version_update: this.options.force_version_update
        }

        // Add user filter if specified
        if (this.options.user_filter.trim()) {
          payload.user_filter = this.options.user_filter.trim()
        }

        const response = await this.$http.post('/api/recalculate', payload)

        if (response.data.success) {
          const stats = response.data.stats
          let message = response.data.message

          // Add detailed stats to message
          if (stats.transaction_updates) {
            const txStats = stats.transaction_updates
            message += `\n\nTransaction Updates:\n`
            message += `• Total: ${txStats.total_transactions}\n`
            message += `• Updated: ${txStats.updated_transactions}\n`
            message += `• Unchanged: ${txStats.unchanged_transactions}\n`
            if (txStats.version_updated_transactions > 0) {
              message += `• Version-only updates: ${txStats.version_updated_transactions}\n`
            }
            if (txStats.backup_created) {
              message += `• Backup created: Yes\n`
            }
          }

          this.$buefy.toast.open({
            duration: 10000,
            message: message,
            type: this.options.dry_run ? 'is-info' : 'is-success'
          })

          this.$emit('success', response.data)
          this.$emit('close')

          // Force refresh if not dry run
          if (!this.options.dry_run) {
            setTimeout(() => {
              this.$router.go(0)
            }, 1000)
          }
        } else {
          throw new Error(response.data.message || 'Recalculation failed')
        }
      } catch (error) {
        console.error('Recalculation error:', error)
        this.$buefy.toast.open({
          duration: 10000,
          message: `Failed to recalculate points: ${error.response?.data?.message || error.message}`,
          type: 'is-danger'
        })
      } finally {
        this.loading = false
      }
    }
  },
  watch: {
    'options.mode'(newMode) {
      // Auto-enable transaction updates for relevant modes
      if (newMode === 'full' || newMode === 'transactions_only') {
        this.options.update_transactions = true
      } else {
        this.options.update_transactions = false
      }
    }
  }
}
</script>

<style scoped>
.modal-card {
  max-width: 600px;
}

.field {
  margin-bottom: 1.5rem;
}

.radio, .checkbox {
  display: block;
  margin-bottom: 0.5rem;
}

.help {
  font-size: 0.875rem;
  color: #6b7280;
  margin-top: 0.25rem;
}

.notification {
  margin-top: 1rem;
}
</style>
