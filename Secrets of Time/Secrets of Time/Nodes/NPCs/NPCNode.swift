//
//  NPCNode.swift
//  Secrets of Time
//
//  Personagem não-hostil com quem o jogador pode interagir para obter dicas
//  sobre os inimigos de cada nível. O NPC transporta o seu próprio conteúdo
//  de diálogo (nome, retrato e falas). Para colocar um NPC num nível basta
//  criar a instância, posicioná-la e adicioná-la à cena.
//  Exibe automaticamente um "!" animado para indicar que é interativo.
//

import SpriteKit

/// Personagem não-hostil com diálogos. Mostra "!" animado para indicar interação.
class NPCNode: SKSpriteNode {

    let displayName: String
    let portraitImageName: String
    let lines: [String]

    /// How close the player has to be (horizontal distance) to start an
    /// interaction attempt.
    let interactionRange: CGFloat

    init(
        name: String,
        portraitImageName: String,
        lines: [String],
        displaySize: CGSize = CGSize(width: 80, height: 104),
        spriteImageName: String? = nil,
        interactionRange: CGFloat = 100
    ) {
        self.displayName = name
        self.portraitImageName = portraitImageName
        self.lines = lines
        self.interactionRange = interactionRange

        let texture: SKTexture
        if let spriteName = spriteImageName {
            let t = SKTexture(imageNamed: spriteName)
            t.filteringMode = .nearest
            texture = t
        } else {
            texture = NPCNode.placeholderTexture(size: displaySize)
        }

        super.init(texture: texture, color: .clear, size: displaySize)
        anchorPoint = CGPoint(x: 0.5, y: 0.0)   // feet at node origin
        zPosition = -5   // behind enemies (0), staff (5) and player (10)
        self.name = "npc"
        addWhiteOutline(texture: texture, displaySize: displaySize)
        addInteractionHint()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// White outline: 8 copies of the sprite offset by 1 pixel, drawn behind.
    private func addWhiteOutline(texture: SKTexture, displaySize: CGSize) {
        // 1-pixel outline in sprite coordinates
        let pixelSize = displaySize.width / texture.size().width
        let d = pixelSize
        let offsets: [(CGFloat, CGFloat)] = [
            (-d,  0), ( d,  0), ( 0, -d), ( 0,  d),
            (-d, -d), ( d, -d), (-d,  d), ( d,  d)
        ]
        for (dx, dy) in offsets {
            let outline = SKSpriteNode(texture: texture, color: .white, size: displaySize)
            outline.colorBlendFactor = 1.0
            outline.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            outline.position = CGPoint(x: dx, y: dy)
            outline.zPosition = -0.1
            outline.texture?.filteringMode = .nearest
            addChild(outline)
        }
    }

    /// "!" above the NPC so the player knows it's interactive.
    private func addInteractionHint() {
        let hint = SKLabelNode(text: "!")
        hint.fontName = "AvenirNext-Bold"
        hint.fontSize = 44
        hint.fontColor = SKColor(red: 1.0, green: 0.92, blue: 0.0, alpha: 1.0)
        hint.position = CGPoint(x: 0, y: size.height - 10)
        hint.zPosition = 10
        addChild(hint)

        // Gentle bounce to draw attention
        let bounce = SKAction.sequence([
            .moveBy(x: 0, y: 6, duration: 0.4),
            .moveBy(x: 0, y: -6, duration: 0.4)
        ])
        hint.run(.repeatForever(bounce))
    }

    private static func placeholderTexture(size: CGSize) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            SKColor.systemTeal.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        let t = SKTexture(image: image)
        t.filteringMode = .nearest
        return t
    }
}
