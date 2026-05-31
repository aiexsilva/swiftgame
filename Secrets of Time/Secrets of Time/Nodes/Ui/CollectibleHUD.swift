import SpriteKit

/// HUD that shows the puzzle pieces the player has picked up. Pieces appear
/// (with a small pop-in) in the order they are collected, using the
/// `PuzzleN.png` sprite art.
/// Add as child of the camera and call `collect(pieceIndex:)` per pickup.
final class CollectibleHUD: SKNode {

    private let iconSize: CGFloat = 30
    private let spacing: CGFloat = 6
    private var pieces: [SKSpriteNode] = []
    private var maxSlots: Int = 0

    /// Sets the planned max number of pieces. Doesn't draw anything by itself.
    func build(maxCount: Int) {
        removeAllChildren()
        pieces.removeAll()
        maxSlots = maxCount
    }

    /// Adds the given piece to the row with a small pop-in animation.
    func collect(pieceIndex: Int) {
        guard maxSlots == 0 || pieces.count < maxSlots else { return }
        let tex = CollectibleNode.texture(for: pieceIndex)
        let icon = SKSpriteNode(texture: tex, size: CGSize(width: iconSize, height: iconSize))
        let i = pieces.count
        icon.position = CGPoint(x: CGFloat(i) * (iconSize + spacing), y: 0)
        icon.setScale(0.0)
        addChild(icon)
        pieces.append(icon)
        icon.run(.scale(to: 1.0, duration: 0.18))
    }

    /// Clears the HUD (e.g. on level restart).
    func reset() {
        for p in pieces { p.removeFromParent() }
        pieces.removeAll()
    }
}
