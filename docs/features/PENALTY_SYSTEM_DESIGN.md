# Penalty System Design - FF Damage Penalties

## Overview

The L4D2 Stats Plugin implements **two different friendly fire penalty systems** with configurable severity levels. This design choice serves different purposes and provides a more nuanced player evaluation system.

## 🚨 **CRITICAL: All Penalties Are Configurable**

**ALL penalty values are defined in `point-system.json` and can be changed without code modifications.**
- Current values are examples of the intended design philosophy
- You can adjust any penalty value to suit your server's needs
- Changes take effect after API restart and recalculation

## Two-Tier Penalty System

### 1. Main Point System (Rankings) - Configurable Penalties
**Used For**: Overall Points and Map Points
**Current FF Penalty**: **-40 points per HP damage** (configurable in point-system.json)
**Purpose**: Long-term ranking and competitive evaluation

### 2. MVP System (Recognition) - Configurable Penalties
**Used For**: MVP All Time and MVP of Map
**Current FF Penalty**: **-3 multiplier** (configurable in point-system.json)
**Purpose**: Recognizing positive contributions and skill

## Design Rationale

### Why Different Penalties?

#### Main Point System (-40 per FF damage)
**Philosophy**: "Friendly fire should heavily impact your ranking"

**Reasoning**:
- **Long-term consequences**: Rankings reflect overall discipline and teamwork
- **Competitive integrity**: Prevents players from being careless with teammates
- **Team-first mentality**: Encourages careful play and team coordination
- **Skill differentiation**: Separates skilled players who avoid FF from careless ones

**Impact Example** (Anlv with 392 FF damage):
```
FF Penalty: 392 × 40 = -15,680 points
Result: Massive impact on ranking position
```

#### MVP System (-3 multiplier)
**Philosophy**: "MVP should focus on positive contributions, not punish mistakes heavily"

**Reasoning**:
- **Skill recognition**: MVP should highlight exceptional performance
- **Positive focus**: Emphasizes what players do well, not what they do wrong
- **Balanced evaluation**: Allows skilled players with minor FF to still be MVP
- **Encourages aggressive play**: Players can take calculated risks without severe punishment

**Impact Example** (Anlv with 392 FF damage):
```
FF Penalty: 392 × 3 = -1,176 points
Result: Minimal impact, allows focus on positive contributions
```

## Real-World Scenarios

### Scenario 1: Aggressive Skilled Player
**Profile**: High kills, high heals, moderate FF damage from aggressive play

**Main Points**: Lower ranking due to harsh FF penalty (appropriate for long-term evaluation)
**MVP Points**: High MVP potential due to light FF penalty (recognizes skill despite minor mistakes)

### Scenario 2: Conservative Safe Player  
**Profile**: Moderate kills, low heals, very low FF damage

**Main Points**: Higher ranking due to disciplined play (rewards team-first approach)
**MVP Points**: Lower MVP potential due to fewer positive contributions

### Scenario 3: Careless Player
**Profile**: High kills, high FF damage, poor teamwork

**Main Points**: Very low ranking due to harsh FF penalty (appropriate punishment)
**MVP Points**: Still low MVP due to accumulated penalties and poor teamwork stats

## System Balance

### Prevents Gaming the System
- **Can't ignore FF entirely**: Even MVP system has penalties
- **Different contexts matter**: Rankings vs recognition serve different purposes
- **Balanced evaluation**: Both systems consider the same positive actions

### Encourages Different Play Styles
- **Ranking climbers**: Focus on disciplined, team-first play
- **MVP seekers**: Focus on exceptional positive contributions
- **Balanced players**: Benefit in both systems

## Configuration

### Main Point System
```json
"penalties": {
  "friendly_fire_damage": {
    "points_per_damage": -40,
    "description": "Penalty per HP damage dealt to teammates",
    "source_field": "survivor_ff"
  }
}
```

### MVP System
```json
"mvp_calculation": {
  "point_values": {
    "penalties": {
      "teammate_kill": -100,
      "ff_damage_multiplier": -3
    }
  }
}
```

## Expected Behaviors

### Player Rankings (Main System)
- **Top players**: Low FF damage, high positive contributions
- **Middle players**: Balanced play with moderate FF
- **Bottom players**: High FF damage or low contributions

### MVP Recognition (MVP System)
- **MVP candidates**: Exceptional positive play, FF damage less impactful
- **Balanced evaluation**: Skill and contribution focused
- **Still penalizes**: Extreme FF still prevents MVP status

## Benefits of Dual System

### 1. Nuanced Player Evaluation
- **Multiple perspectives**: Rankings vs recognition
- **Context-appropriate**: Different penalties for different purposes
- **Skill recognition**: Allows exceptional players to be recognized despite minor flaws

### 2. Encourages Diverse Play Styles
- **Competitive players**: Focus on disciplined ranking climb
- **Skilled players**: Can pursue MVP recognition through exceptional play
- **Team players**: Benefit from both systems through balanced approach

### 3. System Integrity
- **No exploitation**: Both systems have penalties
- **Balanced incentives**: Rewards both discipline and skill
- **Clear purposes**: Each system serves its intended role

## Monitoring & Tuning

### Key Metrics
- **Penalty distribution**: How many players are heavily penalized
- **MVP vs ranking correlation**: Relationship between the two systems
- **Player behavior changes**: Impact on play styles

### Potential Adjustments
- **Penalty values**: Can be tuned based on player behavior
- **Cap adjustments**: Maximum penalties can be modified
- **Rule additions**: New positive actions can be added to balance penalties

---

**Design Philosophy**: "Punish mistakes appropriately for the context, but always recognize exceptional positive contributions."

**Result**: A more sophisticated player evaluation system that serves both competitive ranking and skill recognition purposes.
