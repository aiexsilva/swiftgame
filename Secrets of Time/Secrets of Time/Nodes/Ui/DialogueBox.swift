import SpriteKit

/// Bottom-screen dialogue overlay. Lives as a child of the camera so it
/// stays fixed on screen. Tap anywhere on the box to advance lines; closes
/// automatically after the last one.
class DialogueBox: SKNode {

    /// Called once the player has dismissed the last line.
    var onClose: (() -> Void)?

    private let visibleSize: CGSize
    private let background: SKShapeNode
    private let portrait: SKSpriteNode
    private let nameLabel: SKLabelNode
    private let textLabel: SKLabelNode
    private let advanceHint: SKLabelNode

    private var allLines: [String] = []
    private var currentIndex: Int = 0

    init(visibleSize: CGSize) {
        self.visibleSize = visibleSize

        let boxSize = CGSize(width: visibleSize.width * 0.60, height: 100)
        background = SKShapeNode(rectOf: boxSize, cornerRadius: 14)
        background.fillColor = SKColor(white: 0.05, alpha: 0.85)
        background.strokeColor = SKColor(white: 1.0, alpha: 0.8)
        background.lineWidth = 3
        background.name = "dialogueBg"

        let portraitSize: CGFloat = boxSize.height - 24   // fit inside the box with padding
        portrait = SKSpriteNode(color: SKColor(white: 0.2, alpha: 1.0),
                                size: CGSize(width: portraitSize, height: portraitSize))
        portrait.position = CGPoint(
            x: -boxSize.width / 2 + portraitSize / 2 + 12,
            y: 0   // vertically centered inside the box
        )

        // Text column starts to the right of the portrait.
        let textColumnX = -boxSize.width / 2 + portraitSize + 24

        nameLabel = SKLabelNode(text: "")
        nameLabel.fontName = "AvenirNext-Bold"
        nameLabel.fontSize = 21
        nameLabel.fontColor = .yellow
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.verticalAlignmentMode = .center
        nameLabel.position = CGPoint(x: textColumnX, y: 18)

        textLabel = SKLabelNode(text: "")
        textLabel.fontName = "AvenirNext-Regular"
        textLabel.fontSize = 19
        textLabel.fontColor = .white
        textLabel.horizontalAlignmentMode = .left
        textLabel.verticalAlignmentMode = .center
        textLabel.numberOfLines = 0
        textLabel.preferredMaxLayoutWidth = boxSize.width - portraitSize - 50
        textLabel.position = CGPoint(x: textColumnX, y: -10)

        advanceHint = SKLabelNode(text: "▼ tap")
        advanceHint.fontName = "AvenirNext-DemiBold"
        advanceHint.fontSize = 16
        advanceHint.fontColor = SKColor(white: 1.0, alpha: 0.7)
        advanceHint.horizontalAlignmentMode = .right
        advanceHint.verticalAlignmentMode = .bottom
        advanceHint.position = CGPoint(x: boxSize.width / 2 - 16, y: -boxSize.height / 2 + 12)

        super.init()
        zPosition = 2500
        // Anchor at top of screen, below the HUD.
        position = CGPoint(x: 0, y: visibleSize.height / 2 - boxSize.height / 2 - 64)
        addChild(background)
        background.addChild(portrait)
        background.addChild(nameLabel)
        background.addChild(textLabel)
        background.addChild(advanceHint)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Open with the given NPC dialogue. Replaces any in-progress text.
    func show(name: String, portraitImageName: String, lines: [String]) {
        allLines = lines.isEmpty ? [""] : lines
        currentIndex = 0
        nameLabel.text = name
        textLabel.text = allLines[0]

        let tex = SKTexture(imageNamed: portraitImageName)
        tex.filteringMode = .nearest
        // If the texture didn't resolve (size == .zero), keep the placeholder color.
        if tex.size() != .zero {
            portrait.texture = tex
            portrait.color = .clear
            portrait.colorBlendFactor = 0
        }
    }

    /// Returns true if the touch consumed an advance, false if the dialogue closed.
    @discardableResult
    func advance() -> Bool {
        currentIndex += 1
        if currentIndex >= allLines.count {
            close()
            return false
        }
        textLabel.text = allLines[currentIndex]
        return true
    }

    private func close() {
        removeFromParent()
        onClose?()
    }

    /// Hit-test in this node's local coords.
    func containsPoint(localPoint: CGPoint) -> Bool {
        return background.contains(localPoint)
    }
}
