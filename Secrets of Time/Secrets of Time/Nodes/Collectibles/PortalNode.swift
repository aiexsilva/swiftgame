import SpriteKit

/// Level-exit portal. Starts locked (dimmed) and becomes interactive after
/// the player has collected enough collectibles. Passing through it (physical
/// contact) when unlocked triggers the scene-level transition.
final class PortalNode: SKSpriteNode {

    var isUnlocked: Bool = false {
        didSet { applyUnlockedAppearance() }
    }

    private let counterLabel = SKLabelNode()

    /// Frames `Portal1.png` … `Portal4.png`, ping-pong looped so the swirl
    /// reads as a smooth idle.
    private static let portalTextures: [SKTexture] = {
        let forward: [SKTexture] = (1...4).map { i in
            let t = SKTexture(imageNamed: "Portal\(i)")
            t.filteringMode = .nearest
            return t
        }
        // 1,2,3,4,3,2 ping-pong.
        return forward
    }()

    init(at worldPosition: CGPoint) {
        let displaySize = CGSize(width: 80, height: 80)
        super.init(texture: PortalNode.portalTextures.first,
                   color: .clear,
                   size: displaySize)
        position = worldPosition
        name = "portal"
        anchorPoint = CGPoint(x: 0.5, y: 0.0)
        zPosition = 0
        applyUnlockedAppearance()
        setupCounter(size: displaySize)
        setupPhysics(size: displaySize)
        run(.repeatForever(.animate(
            with: PortalNode.portalTextures,
            timePerFrame: 0.6, resize: false, restore: false
        )), withKey: "portalAnim")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPhysics(size: CGSize) {
        let body = SKPhysicsBody(
            rectangleOf: size,
            center: CGPoint(x: 0, y: size.height / 2)
        )
        body.isDynamic = false
        body.affectedByGravity = false
        body.allowsRotation = false
        body.categoryBitMask = PhysicsCategory.portal
        body.collisionBitMask = 0
        body.contactTestBitMask = PhysicsCategory.player
        physicsBody = body
    }

    private func setupCounter(size: CGSize) {
        counterLabel.fontName = "AvenirNext-Bold"
        counterLabel.fontSize = 18
        counterLabel.fontColor = .white
        counterLabel.horizontalAlignmentMode = .center
        counterLabel.verticalAlignmentMode = .bottom
        // Sits just above the portal sprite.
        counterLabel.position = CGPoint(x: 0, y: size.height + 8)
        counterLabel.zPosition = 1
        counterLabel.text = "0 / 0"
        addChild(counterLabel)
    }

    /// Update the "x / N" label shown above the portal.
    func setCounter(collected: Int, required: Int) {
        counterLabel.text = "\(collected) / \(required)"
        counterLabel.fontColor = collected >= required ? .yellow : .white
    }

    private func applyUnlockedAppearance() {
        alpha = isUnlocked ? 1.0 : 0.4
    }
}
