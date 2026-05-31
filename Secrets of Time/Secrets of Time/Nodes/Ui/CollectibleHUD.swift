import SpriteKit

/// HUD that displays how many collectibles the player has picked up, as a
/// row of small yellow rounded squares (empty squares stay dim).
/// Add as child of the camera and call `setCount(_:)` when one is collected.
final class CollectibleHUD: SKNode {

    private let squareSize: CGFloat = 22
    private let spacing: CGFloat = 6
    private var squares: [SKShapeNode] = []
    private var maxSlots: Int = 0

    private let filledColor = SKColor(red: 1.0, green: 0.85, blue: 0.25, alpha: 1.0)

    /// Sets the maximum number of slots the row may grow to (used for layout
    /// planning). Doesn't draw anything by itself — squares only appear via
    /// `setCount(_:)` as the player collects.
    func build(maxCount: Int) {
        removeAllChildren()
        squares.removeAll()
        maxSlots = maxCount
    }

    /// Shows exactly `count` filled yellow squares — new ones pop in with a
    /// small scale as the player picks them up.
    func setCount(_ count: Int) {
        let target = min(max(count, 0), maxSlots > 0 ? maxSlots : count)

        // Grow: add any missing squares.
        while squares.count < target {
            let i = squares.count
            let s = SKShapeNode(
                rectOf: CGSize(width: squareSize, height: squareSize),
                cornerRadius: 3
            )
            s.fillColor = filledColor
            s.strokeColor = SKColor(white: 1.0, alpha: 0.7)
            s.lineWidth = 1.5
            s.position = CGPoint(x: CGFloat(i) * (squareSize + spacing), y: 0)
            s.setScale(0.0)
            addChild(s)
            squares.append(s)
            s.run(.scale(to: 1.0, duration: 0.18))
        }

        // Shrink: drop any extras (e.g. on restart with count 0).
        while squares.count > target {
            let s = squares.removeLast()
            s.removeFromParent()
        }
    }
}
