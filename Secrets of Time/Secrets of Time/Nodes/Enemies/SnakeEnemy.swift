import SpriteKit

/// Snake enemy that stays idle until the player enters its detection range,
/// then chases the player horizontally. Plays an idle animation while
/// waiting, a walk animation while chasing, and a death frame when killed.
class SnakeEnemy: EnemyNode {

    private let chaseSpeed: CGFloat = 130
    let detectRange: CGFloat

    private enum AnimState { case idle, walk }
    private var currentAnim: AnimState?

    /// Each source pixel of the snake sprites is rendered at this size on
    /// screen. Used so frames of different PNG dimensions (16×16 vs 23×16)
    /// keep the same on-screen pixel scale.
    private static let pixelScale: CGFloat = 3.0

    // MARK: - Animations
    private static let idleTextures: [SKTexture] = pingPong(
        (1...3).map { loadTexture("SnakeIdle\($0)") }
    )
    private static let walkTextures: [SKTexture] = pingPong(
        (1...2).map { loadTexture("SnakeWalk\($0)") }
    )
    private static let deathTexture: SKTexture = loadTexture("SnakeDeath1")

    private static func loadTexture(_ name: String) -> SKTexture {
        let t = SKTexture(imageNamed: name)
        t.filteringMode = .nearest
        return t
    }

    /// Returns `frames + reverseWithoutEndpoints(frames)` so the loop reads
    /// 1→2→…→N→…→2 and then snaps cleanly back to 1.
    private static func pingPong(_ frames: [SKTexture]) -> [SKTexture] {
        guard frames.count > 2 else { return frames }
        return frames + Array(frames.dropFirst().dropLast().reversed())
    }

    init(detectRange: CGFloat = 260) {
        self.detectRange = detectRange
        super.init(
            texture: SnakeEnemy.idleTextures.first ?? SKTexture(),
            displaySize: CGSize(width: 16 * SnakeEnemy.pixelScale,
                                height: 16 * SnakeEnemy.pixelScale),
            bodySize: CGSize(width: 44, height: 28),
            bodyCenterY: 14,
            anchorY: 0,
            isAffectedByGravity: true,
            hp: 4
        )
        play(.idle)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Animation playback

    /// Builds an SKAction that, for each frame, resizes the node to keep a
    /// constant pixel scale and then swaps the texture. This way 23×16 frames
    /// and 16×16 frames render at the same on-screen pixel size instead of
    /// the snake suddenly looking smaller.
    private func makeFrameSequence(_ textures: [SKTexture],
                                   timePerFrame: TimeInterval) -> SKAction {
        let pxScale = SnakeEnemy.pixelScale
        let steps: [SKAction] = textures.flatMap { tex -> [SKAction] in
            let src = tex.size()
            let target = CGSize(width: src.width * pxScale,
                                height: src.height * pxScale)
            return [
                .run { [weak self] in
                    self?.size = target
                    self?.texture = tex
                },
                .wait(forDuration: timePerFrame)
            ]
        }
        return .sequence(steps)
    }

    private func play(_ state: AnimState) {
        guard currentAnim != state else { return }
        currentAnim = state
        removeAction(forKey: "snakeAnim")
        switch state {
        case .idle:
            run(.repeatForever(makeFrameSequence(SnakeEnemy.idleTextures,
                                                 timePerFrame: 0.22)),
                withKey: "snakeAnim")
        case .walk:
            run(.repeatForever(makeFrameSequence(SnakeEnemy.walkTextures,
                                                 timePerFrame: 0.14)),
                withKey: "snakeAnim")
        }
    }

    override func update(deltaTime: TimeInterval, playerPosition: CGPoint) {
        guard !isDead else { return }
        let dx = playerPosition.x - position.x
        let dy = playerPosition.y - position.y
        let dist = hypot(dx, dy)
        guard dist <= detectRange else {
            play(.idle)
            return
        }

        let step = chaseSpeed * CGFloat(deltaTime)
        let move = max(-step, min(step, dx))
        position.x += move
        if move > 0 { xScale = abs(xScale) }
        else if move < 0 { xScale = -abs(xScale) }

        play(abs(move) > 0.1 ? .walk : .idle)
    }

    override func deathAction() -> SKAction? {
        removeAction(forKey: "snakeAnim")
        // Use the same scaling rule so the death frame stays the same on-screen
        // size as the rest of the animations.
        let src = SnakeEnemy.deathTexture.size()
        let target = CGSize(width: src.width * SnakeEnemy.pixelScale,
                            height: src.height * SnakeEnemy.pixelScale)
        return .run { [weak self] in
            self?.size = target
            self?.texture = SnakeEnemy.deathTexture
        }
    }
}
