import SpriteKit

/// HUD that displays the player's hit points as small squares.
/// Add as child of the camera and call `setHealth(current:max:)` when HP changes.
class HealthHUD: SKNode {

    private let squareSize: CGFloat = 28
    private let spacing: CGFloat = 8
    private var squares: [SKShapeNode] = []

    func build(maxHitPoints: Int) {
        removeAllChildren()
        squares.removeAll()
        for i in 0..<maxHitPoints {
            let s = SKShapeNode(rectOf: CGSize(width: squareSize, height: squareSize), cornerRadius: 4)
            s.fillColor = SKColor(red: 0.90, green: 0.20, blue: 0.25, alpha: 1.0)
            s.strokeColor = SKColor(white: 1.0, alpha: 0.85)
            s.lineWidth = 2
            s.position = CGPoint(x: CGFloat(i) * (squareSize + spacing), y: 0)
            addChild(s)
            squares.append(s)
        }
    }

    func setHealth(current: Int, max maxHP: Int) {
        if squares.count != maxHP { build(maxHitPoints: maxHP) }
        for (i, square) in squares.enumerated() {
            square.isHidden = i >= current
        }
    }
}
