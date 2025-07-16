# MVP Calculation Rules

## Overview

The L4D2 Stats Plugin implements **two types of MVP calculations** with configurable point systems that evaluate player performance based on positive contributions and penalties.

## 🚨 **Configuration-Driven System**

**ALL MVP rules are defined in `point-system.json` and are fully configurable.**
- Point values can be adjusted without code changes
- Penalties can be modified to suit server philosophy
- Rules can be enabled/disabled as needed

## Two Types of MVP

### 1. MVP All Time (Global Champion)
- **Scope**: Best player across ALL maps and campaigns
- **Data Source**: Lifetime cumulative statistics
- **Purpose**: Overall champion recognition

### 2. MVP of Map (Map Champion)
- **Scope**: Best player for a specific map/campaign
- **Data Source**: Map-specific statistics
- **Purpose**: Map-specific champion recognition

## Current Point Values (Configurable)

### Positive Actions
- **Common Infected Kills**: 1 point per kill
- **Special Infected Kills**: 6 points per kill
- **Tank Kills**: Up to 100 points per kill
- **Witch Kills**: 15 points per kill
- **Finale Wins**: 1000 points per completion
- **Healing Teammates**: 40 points per heal
- **Reviving Teammates**: 25 points per revive
- **Defibrillating Teammates**: 30 points per defib
- **Item Usage**: 5-15 points per use (molotov, pipe, bile, pills, adrenaline)

### Current Penalties (Configurable)
- **Teammate Kills**: -100 points per friendly kill
- **Friendly Fire Damage**: -3 multiplier per damage point

**Note**: These are current configuration values and can be changed in `point-system.json`.

## Tie-Breaking Criteria

When MVP points are equal, the system uses these criteria in order:

1. **Special Infected Kills** (highest wins)
2. **Friendly Fire Count** (lowest wins)
3. **Common Infected Kills** (highest wins)
4. **Damage Taken** (lowest wins)
5. **Friendly Fire Damage** (lowest wins)

## Configuration Location

**File**: `website-api/config/point-system.json`
**Section**: `mvp_calculation.point_values`

### To Modify MVP Rules:
1. Edit the configuration file
2. Restart the API service
3. Run recalculation if needed

## Design Philosophy

The MVP system is designed to:
1. **Reward Skill**: Higher points for challenging actions (special kills, tank kills)
2. **Encourage Teamwork**: Significant points for healing, reviving, and supporting teammates
3. **Focus on Positive Play**: Lighter penalties compared to ranking system
4. **Recognize Contribution**: Points for tactical item usage and campaign completion
5. **Maintain Balance**: Configurable penalties prevent exploitation

## Key Differences from Ranking System

| Aspect | MVP System | Ranking System |
|--------|------------|----------------|
| **Purpose** | Recognize exceptional performance | Long-term competitive ranking |
| **FF Penalty** | Lighter (current: -3 multiplier) | Harsh (current: -40 per damage) |
| **Focus** | Positive contributions | Balanced discipline + skill |
| **Philosophy** | Skill recognition | Team-first mentality |

## Configuration Flexibility

All MVP rules are fully configurable in `point-system.json`:
- **Point values** can be adjusted for any action
- **Penalties** can be modified to match server philosophy
- **Rules** can be enabled/disabled as needed
- **Tie-breaking criteria** can be reordered

---

**Last Updated**: 2025-01-16
**Status**: Configuration-driven system, all values adjustable