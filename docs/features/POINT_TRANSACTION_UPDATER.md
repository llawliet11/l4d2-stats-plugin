# Point Transaction Updater

## Overview

The Point Transaction Updater is a new feature that allows centralized point calculation in the API instead of relying solely on the SourcePawn plugin. This enables real-time point adjustments without plugin recompilation and ensures consistency across all point calculations.

## Key Features

### ✅ **Centralized Point Calculation**
- All point calculations use `point-system.json` as single source of truth
- No need to recompile plugin when changing point values
- Consistent calculation logic across all systems

### ✅ **Transaction Amount Updates**
- Update individual `stats_points` transaction amounts
- Recalculate based on current `point-system.json` rules
- Maintain complete audit trail of changes

### ✅ **Backup & Safety**
- Automatic backup of original amounts before updates
- Dry run mode for previewing changes
- Rollback capability using backup data

### ✅ **Flexible Targeting**
- Update all users or filter by specific user
- Batch processing for performance
- Progress tracking for large datasets

## API Endpoints

### 1. Enhanced `/api/recalculate` (POST)

Enhanced with transaction update capabilities:

```json
{
  "mode": "full",                    // "full", "stats_only", "transactions_only"
  "update_transactions": true,       // Update individual transaction amounts
  "backup_original": true,           // Backup original amounts before update
  "user_filter": "STEAM_1:0:123",   // Optional: specific user filter
  "dry_run": false,                  // Preview mode without actual changes
  "force_version_update": true       // Update calculation_version for all transactions
}
```

**Response:**
```json
{
  "success": true,
  "message": "Points recalculated successfully...",
  "stats": {
    "users_processed": 1250,
    "total_points_calculated": 15750000,
    "map_users_processed": 8500,
    "total_map_points_calculated": 12500000,
    "transaction_updates": {
      "total_transactions": 45000,
      "updated_transactions": 12500,
      "unchanged_transactions": 32500,
      "version_updated_transactions": 25000,
      "errors": 0,
      "backup_created": true
    }
  }
}
```

### 2. `/api/point-transactions/update` (POST)

Dedicated endpoint for transaction updates only:

```json
{
  "user_filter": null,               // Optional user filter
  "backup_original": true,           // Create backup before update
  "dry_run": false,                  // Preview mode
  "batch_size": 1000,                // Processing batch size
  "force_version_update": true       // Update calculation_version for all transactions
}
```

### 3. `/api/point-transactions/stats` (GET)

Get statistics about point transactions:

```json
{
  "success": true,
  "overall_stats": {
    "total_transactions": 45000,
    "unique_types": 33,
    "backed_up_transactions": 45000,
    "recalculated_transactions": 12500,
    "total_points": 2500000,
    "avg_points": 55.6,
    "min_points": -500,
    "max_points": 1000
  },
  "type_distribution": [
    {
      "type": 2,
      "count": 15000,
      "total_points": 15000,
      "avg_points": 1,
      "backed_up_count": 15000
    }
  ]
}
```

## Database Schema Changes

### New Columns in `stats_points`

```sql
ALTER TABLE stats_points 
ADD COLUMN original_amount SMALLINT(6) DEFAULT NULL COMMENT 'Backup of original amount',
ADD COLUMN calculated_at TIMESTAMP NULL COMMENT 'When amount was recalculated',
ADD COLUMN calculation_version VARCHAR(10) DEFAULT NULL COMMENT 'Point system version used';
```

### Indexes for Performance

```sql
CREATE INDEX idx_stats_points_original_amount ON stats_points(original_amount);
CREATE INDEX idx_stats_points_calculated_at ON stats_points(calculated_at);
CREATE INDEX idx_stats_points_type ON stats_points(type);
```

## Point Calculation Logic

### Type-to-Rule Mapping

The system uses the `type` property in `point-system.json` to map transaction types to calculation rules:

```javascript
// Example mapping
const typeToRuleMap = new Map([
  [2, { points_per_kill: 1, ruleName: 'common_kills' }],      // PType_CommonKill
  [8, { points_per_headshot: 2, ruleName: 'common_headshots' }], // PType_Headshot
  [9, { points_per_damage: -30, ruleName: 'friendly_fire_damage' }] // PType_FriendlyFire
]);
```

### Calculation Process

1. **Load Configuration**: Read `point-system.json`
2. **Build Type Map**: Create mapping from type numbers to rules
3. **Process Transactions**: For each transaction:
   - Look up rule by type
   - Calculate new amount using rule configuration
   - Update if amount differs from current
4. **Update Database**: Batch update with new amounts

## Frontend Integration

### Advanced Recalculation Modal

New modal component provides user-friendly interface for:
- Selecting recalculation mode
- Enabling/disabling transaction updates
- Setting backup options
- User filtering
- Dry run preview

### Quick vs Advanced Options

- **Quick Recalculate**: Traditional stats-only recalculation
- **Advanced Recalculate**: Full control over all options

## Usage Examples

### 1. Update All Transaction Amounts (First Time)

```bash
curl -X POST http://localhost:8081/api/recalculate \
  -H "Content-Type: application/json" \
  -d '{
    "mode": "full",
    "update_transactions": true,
    "backup_original": true,
    "dry_run": false
  }'
```

### 2. Preview Changes for Specific User

```bash
curl -X POST http://localhost:8081/api/point-transactions/update \
  -H "Content-Type: application/json" \
  -d '{
    "user_filter": "STEAM_1:0:123456",
    "backup_original": false,
    "dry_run": true
  }'
```

### 3. Get Transaction Statistics

```bash
curl http://localhost:8081/api/point-transactions/stats
```

## Migration Strategy

### Phase 1: API-Driven Calculations (Current)
- ✅ Enhanced `/recalculate` endpoint
- ✅ Transaction update capability
- ✅ Backup and safety features
- ✅ Frontend integration

### Phase 2: Plugin Simplification (Future)
- Modify plugin to record standardized amounts (e.g., always 1)
- API becomes single source of truth for point values
- Plugin focuses on event detection and recording

### Phase 3: Real-time Updates (Future)
- Live point adjustments without recalculation
- Webhook-based updates
- Dynamic point system modifications

## Benefits

### For Administrators
- **Flexibility**: Change point values without plugin updates
- **Consistency**: Single source of truth for all calculations
- **Safety**: Backup and preview capabilities
- **Transparency**: Complete audit trail of changes

### For Developers
- **Maintainability**: Centralized calculation logic
- **Testability**: Easy to test point calculations
- **Extensibility**: Simple to add new point types
- **Debugging**: Clear mapping between types and rules

### For Users
- **Accuracy**: Consistent point calculations
- **Fairness**: Transparent point system
- **History**: Complete transaction history
- **Real-time**: Immediate effect of rule changes

## Configuration

Point calculation rules are defined in `website-api/config/point-system.json` with the new `type` property mapping to `PointRecordType` enum values.

## Related Files

- **Service**: `website-api/services/PointTransactionUpdater.js`
- **API Routes**: `website-api/routes/misc.js`
- **Frontend Modal**: `website-ui/src/components/admin/RecalculateModal.vue`
- **Database Migration**: `data/migrations/add_point_transaction_backup_columns.sql`
- **Configuration**: `website-api/config/point-system.json`
