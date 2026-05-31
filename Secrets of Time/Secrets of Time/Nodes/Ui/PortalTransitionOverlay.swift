import SpriteKit

/// Fullscreen pink placeholder shown when the player goes through the portal.
/// Holds for `holdDuration`, fades out, then fires `onComplete`. Add as child
/// of the camera so it covers the viewport regardless of scrolling.
final class PortalTransitionOverlay: SKSpriteNode {

    var onComplete: (() -> Void)?

    init(visibleSize: CGSize) {
        super.init(texture: nil, color: .systemPink, size: visibleSize)
        position = .zero
        zPosition = 2600
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        name = "portalOverlay"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present(holdDuration: TimeInterval = 5.0, fadeDuration: TimeInterval = 0.5) {
        run(.sequence([
            .wait(forDuration: holdDuration),
            .fadeOut(withDuration: fadeDuration),
            .run { [weak self] in self?.onComplete?() },
            .removeFromParent()
        ]))
    }
}
