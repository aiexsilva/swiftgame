//
//  Level.swift
//  Secrets of Time
//
//  Define a estrutura de dados de um nível (Level) e as 5 configurações
//  concretas do jogo (Levels.level1 … Levels.level5).
//  Cada nível especifica: spawn do jogador, plataformas, fábricas de inimigos,
//  NPC, decorações, posição do coletável e posição do portal de saída.
//

import SpriteKit

struct Level {
    let playerSpawn: CGPoint
    let platforms: [(CGPoint, CGSize)]
    let enemies: [() -> EnemyNode]
    let npc: NPCNode?
    let npcPosition: CGPoint?
    let decorations: [(String, CGPoint)]
    let collectiblePosition: CGPoint?
    let portalPosition: CGPoint?
}

enum Levels {

    // MARK: - Level 1 · Primavera

    static func level1(size: CGSize) -> Level {
        return Level(
            playerSpawn: CGPoint(x: size.width * -0.80, y: 50),

            platforms: [
                (CGPoint(x: size.width * -0.65, y: 180), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width * -0.55, y: 155), CGSize(width: 128, height: 24)), // raised
                (CGPoint(x: size.width * -0.40, y: 200), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width * -0.33, y: 180), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.33, y: 180), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.50, y: 150), CGSize(width: 128, height: 24)), // raised
                (CGPoint(x: size.width *  0.80, y: 170), CGSize(width: 192, height: 24)),
                (CGPoint(x: size.width *  0.98, y: 200), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  1.20, y: 200), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  1.50, y: 220), CGSize(width: 192, height: 24)),
                (CGPoint(x: size.width *  1.60, y: 170), CGSize(width: 192, height: 24)), // raised
                (CGPoint(x: size.width *  1.70, y: 220), CGSize(width: 192, height: 24)),
            ],

            enemies: [
                {
                    let e = SlimeEnemy(minX: size.width * 0, maxX: size.width * 0.60)
                    e.position = CGPoint(x: size.width * 0.33, y: 60)
                    return e
                },
                {
                    let e = SlimeEnemy(minX: size.width * 1.20, maxX: size.width * 1.55)
                    e.position = CGPoint(x: size.width * 1.20, y: 60)
                    return e
                },
                {
                    // Platform (0.50, 150) top = 162 → pot sits on platform surface
                    let e = FlowerPotEnemy()
                    e.position = CGPoint(x: size.width * 0.50, y: 178)
                    return e
                },
                {
                    // Platform (0.80, 170) top = 182 → pot sits on platform surface
                    let e = FlowerPotEnemy()
                    e.position = CGPoint(x: size.width * 0.80, y: 198)
                    return e
                }
            ],

            npc: NPCNode(
                name: "Mysterious KittyCat",
                portraitImageName: "kittyportrait",
                lines: [
                    "Olá, viajante!",
                    "Cuidado com os vasos nos tetos, caem quando passas por baixo!",
                    "E as slimes patrulham o chão sem parar."
                ],
                spriteImageName: "kitty"
            ),
            npcPosition: CGPoint(x: size.width * -0.62, y: 40), // to the right of player

            decorations: [
                ("housespring", CGPoint(x: size.width * -0.85, y: 40)),
                ("tree",        CGPoint(x: size.width * -0.75, y: 40)),
            ],

            collectiblePosition: CGPoint(x: size.width * 0.98, y: 230),
            portalPosition: CGPoint(x: size.width * 1.65, y: 60)
        )
    }

    // MARK: - Level 2 · Verão

    static func level2(size: CGSize) -> Level {
        return Level(
            playerSpawn: CGPoint(x: size.width * -0.80, y: 50),

            platforms: [
                (CGPoint(x: size.width * -0.80, y: 190), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width * -0.65, y: 155), CGSize(width: 128, height: 24)), // raised
                (CGPoint(x: size.width * -0.45, y: 195), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width * -0.30, y: 160), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.12, y: 195), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.48, y: 155), CGSize(width: 128, height: 24)), // raised
                (CGPoint(x: size.width *  0.72, y: 150), CGSize(width: 192, height: 24)), // raised
                (CGPoint(x: size.width *  1.00, y: 195), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  1.22, y: 205), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  1.48, y: 215), CGSize(width: 192, height: 24)),
                (CGPoint(x: size.width *  1.62, y: 160), CGSize(width: 192, height: 24)), // raised
                (CGPoint(x: size.width *  1.72, y: 215), CGSize(width: 192, height: 24)),
            ],

            enemies: [
                {
                    let e = SnakeEnemy(detectRange: 250)
                    e.position = CGPoint(x: size.width * 0.75, y: 60)
                    return e
                },
                {
                    let e = SnakeEnemy(detectRange: 250)
                    e.position = CGPoint(x: size.width * 1.20, y: 60)
                    return e
                },
                {
                    let e = FlyerEnemy(minX: size.width * 0.35, maxX: size.width * 0.90)
                    e.position = CGPoint(x: size.width * 0.35, y: 250)
                    return e
                },
                {
                    let e = FlyerEnemy(minX: size.width * 1.10, maxX: size.width * 1.60)
                    e.position = CGPoint(x: size.width * 1.10, y: 270)
                    return e
                }
            ],

            npc: NPCNode(
                name: "Mysterious KittyCat",
                portraitImageName: "kittyportrait",
                lines: [
                    "A brisa de verão engana...",
                    "As serpentes espreitam à sombra",
                    "e há criaturas que voam entre as plataformas.",
                    "Não vás distraído!"
                ],
                spriteImageName: "kitty"
            ),
            npcPosition: CGPoint(x: size.width * -0.65, y: 40), // to the right of player

            decorations: [
                ("sunbrella", CGPoint(x: size.width * -0.70, y: 40)),
                ("prancha",   CGPoint(x: size.width *  1.30, y: 40)),
            ],

            collectiblePosition: CGPoint(x: size.width * 1.00, y: 225),
            portalPosition: CGPoint(x: size.width * 1.65, y: 60)
        )
    }

    // MARK: - Level 3 · Outono

    static func level3(size: CGSize) -> Level {
        return Level(
            playerSpawn: CGPoint(x: size.width * -0.80, y: 50),

            platforms: [
                (CGPoint(x: size.width * -0.82, y: 195), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width * -0.68, y: 160), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width * -0.50, y: 185), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width * -0.35, y: 145), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.08, y: 200), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.45, y: 160), CGSize(width: 128, height: 24)), // raised
                (CGPoint(x: size.width *  0.68, y: 155), CGSize(width: 192, height: 24)), // raised
                (CGPoint(x: size.width *  0.95, y: 205), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  1.18, y: 200), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  1.52, y: 225), CGSize(width: 192, height: 24)),
                (CGPoint(x: size.width *  1.58, y: 155), CGSize(width: 192, height: 24)),
                (CGPoint(x: size.width *  1.68, y: 225), CGSize(width: 192, height: 24)),
            ],

            enemies: [
                {
                    let e = JumperEnemy()
                    e.position = CGPoint(x: size.width * 0.45, y: 60)
                    return e
                },
                {
                    let e = JumperEnemy()
                    e.position = CGPoint(x: size.width * 1.20, y: 60)
                    return e
                },
                {
                    // Hangs between platform (0.68, 155) and ground
                    let e = SpiderEnemy(x: size.width * 0.68, platformY: 140)
                    return e
                },
                {
                    // Hangs between platform (1.52, 225) and ground
                    let e = SpiderEnemy(x: size.width * 0.95, platformY: 210)
                    return e
                }
            ],

            npc: NPCNode(
                name: "Mysterious KittyCat",
                portraitImageName: "kittyportrait",
                lines: [
                    "As folhas caem e os perigos aumentam!",
                    "Há criaturas que saltam como loucas...",
                    "e aranhas presas às plataformas que sobem e descem.",
                    "Não as consegues eliminar, só evitar!"
                ],
                spriteImageName: "kitty"
            ),
            npcPosition: CGPoint(x: size.width * -0.70, y: 40), // to the right of player

            decorations: [
                ("stop", CGPoint(x: size.width * -0.75, y: 40)),
                ("tree", CGPoint(x: size.width *  1.30, y: 40)),
            ],

            collectiblePosition: CGPoint(x: size.width * 0.95, y: 235),
            portalPosition: CGPoint(x: size.width * 1.62, y: 60)
        )
    }

    // MARK: - Level 4 · Inverno

    static func level4(size: CGSize) -> Level {
        return Level(
            playerSpawn: CGPoint(x: size.width * -0.80, y: 50),

            platforms: [
                (CGPoint(x: size.width * -0.85, y: 200), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width * -0.70, y: 165), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width * -0.52, y: 195), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width * -0.35, y: 155), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.10, y: 200), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.52, y: 160), CGSize(width: 128, height: 24)), // raised
                (CGPoint(x: size.width *  0.70, y: 155), CGSize(width: 192, height: 24)), // raised
                (CGPoint(x: size.width *  0.98, y: 200), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  1.20, y: 200), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  1.50, y: 220), CGSize(width: 192, height: 24)),
                (CGPoint(x: size.width *  1.60, y: 150), CGSize(width: 192, height: 24)),
                (CGPoint(x: size.width *  1.70, y: 220), CGSize(width: 192, height: 24)),
            ],

            enemies: [
                {
                    let e = TurretEnemy()
                    e.position = CGPoint(x: size.width * 0, y: 60)
                    return e
                },
                {
                    let e = TurretEnemy()
                    e.position = CGPoint(x: size.width * 1.30, y: 60)
                    return e
                },
                {
                    let e = PenguinEnemy(minX: size.width * 0.05, maxX: size.width * 0.55)
                    e.position = CGPoint(x: size.width * 0.15, y: 60)
                    return e
                },
            ],

            npc: NPCNode(
                name: "Mysterious KittyCat",
                portraitImageName: "kittywinterportrait",
                lines: [
                    "O frio chegou e trouxe novos horrores!",
                    "Há uma criatura imóvel que dispara projéteis...",
                    "e um pinguim que se atira de um lado ao outro.",
                    "Evita o que não consegues matar!"
                ],
                spriteImageName: "kittywinter"
            ),
            npcPosition: CGPoint(x: size.width * -0.65, y: 40), // to the right of player

            decorations: [
                ("housewinter", CGPoint(x: size.width * -0.75, y: 40)),
                ("treewinter",  CGPoint(x: size.width *  1.30, y: 40)),
            ],

            collectiblePosition: CGPoint(x: size.width * 0.98, y: 230),
            portalPosition: CGPoint(x: size.width * 1.65, y: 60)
        )
    }

    // MARK: - Level 5 · Vazio

    static func level5(size: CGSize) -> Level {
        return Level(
            playerSpawn: CGPoint(x: size.width * -0.80, y: 50),

            platforms: [
                (CGPoint(x: size.width *  0, y: 180), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.05, y: 180), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.10, y: 180), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.15, y: 350), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.20, y: 350), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.25, y: 350), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.30, y: 180), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.35, y: 180), CGSize(width: 128, height: 24)),
                (CGPoint(x: size.width *  0.40, y: 180), CGSize(width: 128, height: 24)),

            ],

            enemies: [],   // Boss is set up separately by GameScene.setupBoss()

            npc: nil,
            npcPosition: nil,

            decorations: [],

            collectiblePosition: nil,
            portalPosition: nil
        )
    }
}
