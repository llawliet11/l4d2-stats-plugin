# MVP Calculation Rules

This document outlines the comprehensive MVP (Most Valuable Player) calculation system for the L4D2 Stats Plugin.

## Overview

The MVP system uses a points-based calculation that considers various gameplay actions, teamwork contributions, and penalties. The player with the highest total MVP points is awarded MVP status.

## Point Values

### Positive Actions

#### Combat Actions
- **Common Infected Kills**: +1 point per kill
- **Special Infected Kills**: +6 points per kill
- **Tank Kills**: +100 points per kill
- **Witch Kills**: +15 points per kill
- **Finale Wins**: +1000 points per completion

#### Teamwork & Support
- **Healing Teammates**: +40 points per heal
- **Reviving Teammates**: +25 points per revive
- **Defibrillating Teammates**: +30 points per defib

#### Item Usage
- **Molotov Usage**: +5 points per use
- **Pipe Bomb Usage**: +5 points per use
- **Bile Bomb Usage**: +5 points per use
- **Pills Usage**: +10 points per use
- **Adrenaline Usage**: +15 points per use

#### Damage Management
- **Damage Taken Bonus**: +(average_damage_taken - player_damage_taken) × 0.5
  - Rewards players who take less damage than the team average

### Penalties

- **Teammate Kills**: -100 points per friendly kill
- **Friendly Fire Damage**: -2 points per damage point dealt to teammates

## Calculation Formula

```
MVP Points = 
  (Special Kills × 6) +
  (Common Kills × 1) +
  (Tank Kills × 100) +
  (Witch Kills × 15) +
  (Heals × 40) +
  (Revives × 25) +
  (Defibs × 30) +
  (Finales Won × 1000) +
  (Molotovs × 5) +
  (Pipe Bombs × 5) +
  (Bile Bombs × 5) +
  (Pills × 10) +
  (Adrenaline × 15) +
  (Damage Taken Bonus × 0.5) +
  (Teammate Kills × -100) +
  (Friendly Fire Damage × -2)
```

## Implementation Details

### Sessions Page
- Displays aggregated user statistics from the `stats_users` table
- Calculates MVP points for each player using real database values
- Orders players by MVP points (highest first)
- Marks the top player as MVP with visual indicators

### Campaign Details
- Uses the traditional ranking system for individual campaign MVP
- Orders by: Special Kills (desc) → FF Count (asc) → Zombie Kills (desc) → Damage Taken (asc) → FF Damage (asc)

### Configuration
- Point values are stored in `/website-api/config/point-calculation-rules.json`
- System is configurable and can be adjusted without code changes
- Rules are loaded dynamically by the API

## Design Philosophy

The MVP system is designed to:
1. **Reward Skill**: Higher points for challenging actions (special kills, tank kills)
2. **Encourage Teamwork**: Significant points for healing, reviving, and supporting teammates
3. **Promote Efficiency**: Bonus for taking less damage than average
4. **Discourage Griefing**: Heavy penalties for team kills and friendly fire
5. **Value Contribution**: Points for tactical item usage and campaign completion

## Update History

- **v1.0**: Initial MVP system with basic combat metrics
- **v1.1**: Added teamwork actions (heals, revives, defibs)
- **v1.2**: Added item usage tracking and damage taken bonus
- **v1.3**: Updated friendly fire penalty to -2 per damage point
- **v1.4**: Added comprehensive positive actions for throwables and consumables

Last Updated: 2025-07-14