# Secrets of Time — Game Plan

---

## Elevator Pitch

> Follow Spiky, a young mage, on a journey through the seasons of time.
> Defeat enemies, collect ancient artifacts, and find the teleports that lead to the next era —
> before the force that froze time consumes everything.

---

## Game Concept

**Secrets of Time** is a 2D side-scrolling platformer for iOS built with Swift and SpriteKit.
The player controls Spiky, a mage traveling through thematic worlds representing the seasons.
Each world is corrupted by a mysterious force that has stopped time, and Spiky must fight through
enemies and collect artifacts to unlock the teleport that advances him to the next era.

The final world  **Lost Time**  is a void-like dimension where time no longer exists,
and Spiky confronts the entity responsible for stopping it all.

### Worlds (Full Vision)

| Level | Theme | Description |
|-------|-------|-------------|
| 1 | Spring | Lush green fields, light enemies, tutorial feel |
| 2 | Summer | Hot desert/beach, faster enemies |
| 3 | Autumn | Dark forest, trickier platforming |
| 4 | Winter | Icy platforms, slippery movement |
| 5 | Lost Time | Void/empty dimension, final boss fight |

---

## Core Gameplay Loop

```
Start Level
    ↓
Explore platform layout
    ↓
Shoot enemies (magic projectiles) → earn score
Collect artifacts scattered across the level → earn score
    ↓
Reach score threshold for this level
    ↓
Teleport unlocks
    ↓
Enter teleport → next level
    ↓
[After level 5: Boss fight → Win screen]
```

### Player Actions

| Action | Input |
|--------|-------|
| Move left / right | On-screen D-pad |
| Jump | Jump button |
| Shoot magic projectile | Fire button (tap) |

### Score System

- Each level has a **minimum score threshold** to unlock the teleport
- Artifacts give more score than enemy kills, encouraging exploration
- A score counter and threshold bar are visible on the HUD at all times

---

## Why It's Fun

- **Clear, satisfying goal per level:** the player always knows what they're working toward
- **Exploration reward:** artifacts are hidden, encouraging players to explore the whole level
- **Thematic progression:** each season feels and looks different — visual variety keeps it fresh
- **Simple combat with a skill ceiling:** projectile aiming adds a small layer of skill
- **Story hook:** the mystery of who stopped time creates curiosity to reach the next world

---

## MVP Scope (4-week target)

The MVP is the **minimum playable version** that proves the core concept works.
It should be fully functional and polished within its scope.

### MVP Includes

- [x] **2 playable levels:** Spring (tutorial) + Summer
- [x] **Core movement:** walk left/right, jump
- [x] **Shooting mechanic:** magic projectile fires in the direction the player faces
- [x] **1 enemy type:** moves back and forth on a platform, dies in 1 hit
- [x] **Artifact collectibles:** placed statically across the level
- [x] **Score system:** counter on HUD, threshold visible, teleport unlocks when reached
- [x] **Teleport object:** appears/activates when score threshold is met
- [x] **3 UI screens:** Main Menu → Game Scene → Game Over / Level Complete
- [x] **Basic audio:** background music per level + sound effect for shoot/collect/die

### MVP Does NOT Include

- [ ] Levels 3, 4, 5 (Autumn, Winter, Lost Time)
- [ ] Boss fight
- [ ] Dialogue
- [ ] Multiple enemy types
- [ ] Special abilities
- [ ] Save/load progress between sessions
- [ ] Animated character sprite sheets (placeholder shapes accepted for MVP)

---

## Technical Plan (SpriteKit)

### Project Structure

```
SpikysJourney/
├── Scenes/
│   ├── MenuScene.swift          ← Main menu
│   ├── GameScene.swift          ← Core gameplay (reused per level)
│   └── GameOverScene.swift      ← Win / lose screen
├── Nodes/
│   ├── PlayerNode.swift         ← Spiky: movement + shooting logic
│   ├── EnemyNode.swift          ← Patrol enemy AI
│   ├── ProjectileNode.swift     ← Magic projectile behavior
│   └── ArtifactNode.swift       ← Collectible item
├── Managers/
│   ├── ScoreManager.swift       ← Score tracking + threshold logic
│   └── LevelManager.swift       ← Level loading + teleport trigger
└── Resources/
    ├── Levels/                  ← .sks files or tile configs per level
    ├── Sounds/
    └── Sprites/
```

### Key SpriteKit Systems Used

| Feature | SpriteKit Tool |
|---------|----------------|
| Player & enemy rendering | `SKSpriteNode` |
| Physics & collisions | `SKPhysicsBody`, `SKPhysicsContactDelegate` |
| Projectile movement | `SKAction` (move + remove on contact) |
| Platform layout | `SKTileMapNode` or manual `SKSpriteNode` platforms |
| HUD (score, threshold bar) | `SKLabelNode`, `SKShapeNode` |
| Camera following player | `SKCameraNode` |
| Scene transitions | `SKTransition` |
| Background music | `SKAudioNode` |

### Collision Groups (Bitmask Plan)

```
Player     → 0b0001
Enemy      → 0b0010
Projectile → 0b0100
Artifact   → 0b1000
Platform   → 0b10000
Teleport   → 0b100000
```

---

## Biggest Risk + Mitigation

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Level design takes too long | High | Use simple flat/staircase platform layouts for MVP; add complexity in stretch |
| Physics bugs (player falls through platforms, projectiles glitch) | Medium | Test physics collisions in isolation early in week 1; fix before building features on top |
| Scope creep (wanting to add "just one more thing") | High | Freeze MVP feature list by end of week 2; only add stretch goals in week 4 if MVP is stable |
| Uneven workload across 3 people | Medium | Assign clear ownership: one person per area (Player/Enemy logic, Level/Scene management, UI/Audio) |
| Art assets slow down progress | Medium | Use colored rectangles as placeholders; swap for real sprites only after mechanics work |

---

## Stretch Goals (if time allows after MVP)

These are ordered by priority — add them in order if the team has capacity:

1. **Level 3 — Autumn:** dark forest aesthetic, introduce a second enemy type that jumps
2. **Level 4 — Winter:** slippery platform physics, faster enemies
3. **Story text cards:** simple full-screen text between levels (no animations needed)
4. **Level 5 + Boss fight:** Lost Time void world + boss with a health bar and attack pattern
5. **Animated sprites:** replace placeholder art with sprite sheet animations

---

## 4-Week Timeline

| Week | Goal |
|------|------|
| 1 | Project setup, player movement + jump, basic platform scene |
| 2 | Shooting + enemy, artifact + score system, teleport unlock |
| 3 | Level 2 (Summer), HUD polish, scene transitions (menu, game over) |
| 4 | Bug fixing, audio, playtesting, stretch goals if stable |
