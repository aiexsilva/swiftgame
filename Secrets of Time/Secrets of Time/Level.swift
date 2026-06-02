//
//  Level.swift
//  Secrets of Time
//
//  Created by Diana Silva on 02/06/2026.
//

import SpriteKit

struct Level {
    let playerSpawn: CGPoint
    let platforms: [(CGPoint, CGSize)]
    let enemies: [() -> EnemyNode]
    let npc: NPCNode?
    let npcPosition: CGPoint?
    let decorations: [(String, CGPoint)]
}

enum Levels {

    // MARK: - Level 1 · Primavera

    static func level1(size: CGSize) -> Level {
        return Level(
            playerSpawn: CGPoint(x: 120, y: 200),

            platforms: [
                (CGPoint(x: size.width * -0.65, y: 180), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width * -0.55, y: 130), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width * -0.40, y: 200), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width * -0.33, y: 180), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.33, y: 180), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.50, y: 110), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.80, y: 170), CGSize(width: 192, height: 24)),
                (CGPoint(x: size.width *  0.98, y: 200), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  1.20, y: 200), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  1.50, y: 220), CGSize(width: 192, height: 24)),
                (CGPoint(x: size.width *  1.60, y: 150), CGSize(width: 192, height: 24)),
                (CGPoint(x: size.width *  1.70, y: 220), CGSize(width: 192, height: 24)),
            ],

            enemies: [
                {
                    let e = SlimeEnemy(minX: size.width * 0.40, maxX: size.width * 0.70)
                    e.position = CGPoint(x: size.width * 0.40, y: 60)
                    return e
                }
            ],

            npc: NPCNode(
                name: "Mysterious KittyCat",
                portraitImageName: "kittyportrait",
                lines: [
                    "Hello traveler.",
                    "Be careful ahead."
                ],
                spriteImageName: "kitty"
            ),
            npcPosition: CGPoint(x: size.width * 0.1, y: 40),

            decorations: [
                ("housespring", CGPoint(x: size.width * -0.85, y: 40)),
                ("tree",        CGPoint(x: size.width * -0.75, y: 40)),
            ]
        )
    }

    // MARK: - Level 2 · Verão

    static func level2(size: CGSize) -> Level {
        return Level(
            playerSpawn: CGPoint(x: 0, y: 200),

            platforms: [
                (CGPoint(x: size.width * -0.80, y: 190), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width * -0.65, y: 150), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width * -0.45, y: 195), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width * -0.30, y: 160), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.12, y: 195), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.48, y: 145), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.72, y: 125), CGSize(width: 192, height: 24)),
                (CGPoint(x: size.width *  1.00, y: 195), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  1.22, y: 205), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  1.48, y: 215), CGSize(width: 192, height: 24)),
                (CGPoint(x: size.width *  1.62, y: 145), CGSize(width: 192, height: 24)),
                (CGPoint(x: size.width *  1.72, y: 215), CGSize(width: 192, height: 24)),
            ],

            enemies: [
                {
                    let e = SlimeEnemy(minX: size.width * 0.35, maxX: size.width * 0.65)
                    e.position = CGPoint(x: size.width * 0.35, y: 60)
                    return e
                },
                {
                    let e = SnakeEnemy(detectRange: 250)
                    e.position = CGPoint(x: size.width * 1.10, y: 60)
                    return e
                }
            ],

            npc: NPCNode(
                name: "Mysterious KittyCat",
                portraitImageName: "kittyportrait",
                lines: [
                    "Welcome, traveler.",
                    "The summer heat is fierce.",
                    "Watch your step on the sand."
                ],
                spriteImageName: "kitty"
            ),
            npcPosition: CGPoint(x: size.width * -0.4, y: 40),

            decorations: [
                ("sunbrella", CGPoint(x: size.width * -0.70, y: 40)),
                ("prancha",   CGPoint(x: size.width *  1.30, y: 40)),
            ]
        )
    }

    // MARK: - Level 3 · Outono

    static func level3(size: CGSize) -> Level {
        return Level(
            playerSpawn: CGPoint(x: 0, y: 200),

            platforms: [
                (CGPoint(x: size.width * -0.82, y: 195), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width * -0.68, y: 160), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width * -0.50, y: 185), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width * -0.35, y: 145), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.08, y: 200), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.45, y: 155), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.68, y: 135), CGSize(width: 192, height: 24)),
                (CGPoint(x: size.width *  0.95, y: 205), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  1.18, y: 200), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  1.52, y: 225), CGSize(width: 192, height: 24)),
                (CGPoint(x: size.width *  1.58, y: 155), CGSize(width: 192, height: 24)),
                (CGPoint(x: size.width *  1.68, y: 225), CGSize(width: 192, height: 24)),
            ],

            enemies: [
                {
                    let e = SlimeEnemy(minX: size.width * 0.30, maxX: size.width * 0.60)
                    e.position = CGPoint(x: size.width * 0.30, y: 60)
                    return e
                },
                {
                    let e = SnakeEnemy(detectRange: 260)
                    e.position = CGPoint(x: size.width * 0.90, y: 60)
                    return e
                },
                {
                    let e = SnakeEnemy(detectRange: 220)
                    e.position = CGPoint(x: size.width * 1.40, y: 60)
                    return e
                }
            ],

            npc: NPCNode(
                name: "Mysterious KittyCat",
                portraitImageName: "kittyportrait",
                lines: [
                    "The leaves are falling...",
                    "Autumn brings new dangers.",
                    "Stay alert."
                ],
                spriteImageName: "kitty"
            ),
            npcPosition: CGPoint(x: size.width * -0.4, y: 40),

            decorations: [
                ("stop", CGPoint(x: size.width * -0.75, y: 40)),
                ("tree", CGPoint(x: size.width *  1.30, y: 40)),
            ]
        )
    }

    // MARK: - Level 4 · Inverno

    static func level4(size: CGSize) -> Level {
        return Level(
            playerSpawn: CGPoint(x: 0, y: 200),

            platforms: [
                (CGPoint(x: size.width * -0.85, y: 200), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width * -0.70, y: 165), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width * -0.52, y: 195), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width * -0.35, y: 155), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.10, y: 200), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.52, y: 148), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.70, y: 128), CGSize(width: 192, height: 24)),
                (CGPoint(x: size.width *  0.98, y: 200), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  1.20, y: 200), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  1.50, y: 220), CGSize(width: 192, height: 24)),
                (CGPoint(x: size.width *  1.60, y: 150), CGSize(width: 192, height: 24)),
                (CGPoint(x: size.width *  1.70, y: 220), CGSize(width: 192, height: 24)),
            ],

            enemies: [
                {
                    let e = SnakeEnemy(detectRange: 250)
                    e.position = CGPoint(x: size.width * 0.50, y: 60)
                    return e
                },
                {
                    let e = SnakeEnemy(detectRange: 250)
                    e.position = CGPoint(x: size.width * 1.10, y: 60)
                    return e
                },
                {
                    let e = SlimeEnemy(minX: size.width * 1.45, maxX: size.width * 1.75)
                    e.position = CGPoint(x: size.width * 1.45, y: 60)
                    return e
                }
            ],

            npc: NPCNode(
                name: "Mysterious KittyCat",
                portraitImageName: "kittywinterportrait",
                lines: [
                    "It's freezing out here...",
                    "The ice makes everything slippery.",
                    "Do you have what it takes?"
                ],
                spriteImageName: "kittywinter"
            ),
            npcPosition: CGPoint(x: size.width * -0.4, y: 70),

            decorations: [
                ("housewinter", CGPoint(x: size.width * -0.75, y: 40)),
                ("treewinter",  CGPoint(x: size.width *  1.30, y: 40)),
            ]
        )
    }

    // MARK: - Level 5 · Vazio

    static func level5(size: CGSize) -> Level {
        return Level(
            playerSpawn: CGPoint(x: 0, y: 200),

            platforms: [
                (CGPoint(x: size.width *  0, y: 200), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.05, y: 200), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.10, y: 200), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.35, y: 300), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.40, y: 300), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.45, y: 300), CGSize(width: 192, height: 24)),
                (CGPoint(x: size.width *  0.70, y: 200), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.75, y: 200), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.80, y: 200), CGSize(width: 128, height: 24)),

            ],

            enemies: [
                {
                    let e = SnakeEnemy(detectRange: 300)
                    e.position = CGPoint(x: size.width * 0.60, y: 60)
                    return e
                },
                {
                    let e = SnakeEnemy(detectRange: 300)
                    e.position = CGPoint(x: size.width * 1.20, y: 60)
                    return e
                }
            ],

            npc: nil,
            npcPosition: nil,

            decorations: []
        )
    }
}
