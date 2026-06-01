import SpriteKit

/// Fullscreen placeholder shown when the boss dies, before the actual
/// "YOU WIN" overlay appears. Same pattern as `PortalTransitionOverlay`.
final class BossDefeatOverlay: SKSpriteNode {

    var onComplete: (() -> Void)?

    init(visibleSize: CGSize) {
        super.init(texture: nil, color: .systemIndigo, size: visibleSize)
        position = .zero
        zPosition = 2600
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        name = "bossDefeatOverlay"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present(holdDuration: TimeInterval = 4.0, fadeDuration: TimeInterval = 0.5) {
        run(.sequence([
            .wait(forDuration: holdDuration),
            .fadeOut(withDuration: fadeDuration),
            .run { [weak self] in self?.onComplete?() },
            .removeFromParent()
        ]))
    }
}
