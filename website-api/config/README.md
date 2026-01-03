# L4D2 Stats API Configuration

This directory contains configuration files that allow you to modify calculation rules without rebuilding the API.

## calculation-rules.json

This file contains all the configurable calculation rules for the L4D2 stats system.

### Configuration Sections

#### MVP Calculation
Controls how campaign MVP is determined:
```json
"mvp_calculation": {
  "criteria": [
    {
      "field": "SpecialInfectedKills",
      "direction": "desc",
      "priority": 1,
      "description": "Special Infected Killed (highest)"
    }
  ]
}
```

#### Top Weapon Calculation
Controls how player's top weapon is determined:
```json
"top_weapon_calculation": {
  "source_table": "stats_weapons_usage",
  "criteria": {
    "field": "minutesUsed",
    "direction": "desc"
  }
}
```

Available criteria fields:
- `minutesUsed` - Total time using weapon
- `totalDamage` - Total damage dealt with weapon  
- `kills` - Total kills with weapon
- `headshots` - Total headshots with weapon

#### Cache Durations
Controls how long API responses are cached (in seconds):
```json
"cache_durations": {
  "campaign_values": 600,
  "campaign_details": 120,
  "user_top": 60
}
```

#### Pagination Settings
Controls default page sizes and limits:
```json
"pagination": {
  "campaigns_per_page": 4,
  "sessions_per_page": 10,
  "max_per_page": 100
}
```

### How to Apply Changes

1. Edit the `calculation-rules.json` file
2. Restart the API service: `docker compose restart l4d2stats-api`
3. Changes take effect immediately

### Examples

**Change MVP criteria to prioritize damage over kills:**
```json
"mvp_calculation": {
  "criteria": [
    {"field": "SurvivorDamage", "direction": "asc", "priority": 1},
    {"field": "DamageTaken", "direction": "asc", "priority": 2},
    {"field": "SpecialInfectedKills", "direction": "desc", "priority": 3}
  ]
}
```

**Change top weapon to be based on damage instead of time:**
```json
"top_weapon_calculation": {
  "criteria": {
    "field": "totalDamage",
    "direction": "desc"
  }
}
```

**Increase cache times for better performance:**
```json
"cache_durations": {
  "campaign_details": 300,
  "user_top": 180
}
```

### Notes

- The API loads this config file on startup
- If the file is missing or malformed, the API uses built-in defaults
- Changes require an API restart to take effect
- All fields are optional - missing fields use defaults