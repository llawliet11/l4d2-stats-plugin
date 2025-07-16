# Database Migrations

This folder contains SQL migration scripts for the L4D2 Stats Plugin database.

## Migration Files

### Friendly Fire Logic Separation (Latest)
- **`separate_ff_logic_migration.sql`** - Separates friendly fire penalty calculation from actual damage display
- **`add_ff_penalty_to_stats_map_users.sql`** - Adds survivor_ff_penalty column to stats_map_users table

**Purpose**: 
- `survivor_ff` now shows actual damage (e.g., 392 HP)
- `survivor_ff_penalty` stores penalty points (e.g., 15,693 points)
- Provides user-friendly display while maintaining accurate point calculations

### Historical Migrations
- **`comprehensive_stats_fix.sql`** - Comprehensive stats data fixes
- **`fix_friendly_fire_received.sql`** - Fixes friendly fire received calculations
- **`fix_orphaned_points.sql`** - Fixes orphaned point records
- **`fix_playtime_discrepancies.sql`** - Fixes playtime calculation issues
- **`remove_foreign_keys.sql`** - Removes problematic foreign key constraints
- **`test_map_users_plugin.sql`** - Test script for map users plugin functionality

## How to Run Migrations

### On ssh-lavender (Production)
```bash
# Navigate to project directory
cd /home/niafam/projects/GAMES/left4dead2-stats

# Run migration
docker exec -i services_l4d2stats-database.1.had0eoarkzn90vwap7k13pvq4 \
  mariadb -u mariadb -p4d1be76f69556177cc2b left4dead2 \
  < database_migrations/migration_file.sql
```

### On Local Development
```bash
# Copy migration to container
docker cp database_migrations/migration_file.sql l4d2stats-database:/tmp/

# Execute migration
docker exec l4d2stats-database \
  mariadb -u root -proot left4dead2 \
  < /tmp/migration_file.sql
```

## Migration Order

If setting up from scratch, run migrations in this order:

1. `remove_foreign_keys.sql` - Remove constraints
2. `comprehensive_stats_fix.sql` - Fix core data issues
3. `fix_playtime_discrepancies.sql` - Fix playtime calculations
4. `fix_friendly_fire_received.sql` - Fix FF received data
5. `fix_orphaned_points.sql` - Fix orphaned points
6. `separate_ff_logic_migration.sql` - Separate FF logic (stats_users)
7. `add_ff_penalty_to_stats_map_users.sql` - Separate FF logic (stats_map_users)

## Backup Strategy

Each migration script creates its own backup tables:
- `stats_users_*_backup` - Backup of stats_users data
- `stats_map_users_*_backup` - Backup of stats_map_users data

## Verification

After running migrations, verify:
1. Data consistency between tables
2. No data loss occurred
3. Application functionality works correctly
4. Point calculations are accurate

## Notes

- Always test migrations on development environment first
- Keep backup tables until migration is verified successful
- Some migrations may take time on large datasets
- Monitor database performance during migration execution
