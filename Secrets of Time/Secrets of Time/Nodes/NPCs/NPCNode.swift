import SpriteKit

/// A non-hostile character the player can talk to.
///
/// The NPC carries its own dialogue payload (name + portrait + lines) so
/// adding an NPC to a level is one line: create it, position it, addChild.
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
        displaySize: CGSize = CGSize(width: 48, height: 64),
        spriteImageName: String? = nil,
        interactionRange: CGFloat = 70
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
        addInteractionHint()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Small "!" above the NPC so the player knows it's interactive.
    private func addInteractionHint() {
        let hint = SKLabelNode(text: "!")
        hint.fontName = "AvenirNext-Bold"
        hint.fontSize = 22
        hint.fontColor = .yellow
        hint.position = CGPoint(x: 0, y: size.height + 8)
        hint.zPosition = 1
        addChild(hint)
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
