import SpriteKit

/// Floating wooden staff that follows the player with a slight lag and a
/// gentle vertical bob. Lives as a sibling of the player in the scene so it
/// can be interpolated independently.
class StaffNode: SKSpriteNode {

    /// Horizontal offset from the player (mirrored when facing left).
    private let sideOffset: CGFloat = 38
    /// Vertical offset above the player's feet (`player.position.y`).
    /// Picks the player's mid-body so the staff floats around the mage's hand.
    private let verticalOffset: CGFloat = 30

    /// Lerp speed — lower values give more "drag" / lag.
    private let followSpeed: CGFloat = 4.0

    /// Bobbing motion.
    private let bobAmplitude: CGFloat = 4
    private let bobFrequency: Double = 1.6   // cycles per second
    private var bobTime: TimeInterval = 0

    init() {
        let tex = SKTexture(imageNamed: "staff_wood")
        tex.filteringMode = .nearest
        super.init(texture: tex, color: .clear, size: CGSize(width: 56, height: 56))
        zPosition = 5    // behind player (10), in front of enemies (0) and NPCs (-5)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Called every frame from GameScene.
    func update(deltaTime: TimeInterval, playerPosition: CGPoint, facingRight: Bool) {
        bobTime += deltaTime
        let bobY = CGFloat(sin(bobTime * bobFrequency * 2 * .pi)) * bobAmplitude

        let dirX: CGFloat = facingRight ? 1 : -1
        let target = CGPoint(
            x: playerPosition.x + sideOffset * dirX,
            y: playerPosition.y + verticalOffset + bobY
        )

        // Smooth follow with drag.
        let t = min(1, followSpeed * CGFloat(deltaTime))
        position = CGPoint(
            x: position.x + (target.x - position.x) * t,
            y: position.y + (target.y - position.y) * t
        )

        // Mirror sprite with facing.
        xScale = facingRight ? abs(xScale) : -abs(xScale)
    }
}
