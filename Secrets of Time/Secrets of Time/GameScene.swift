//
//  GameScene.swift
//  Secrets of Time
//
//  Test scene: player on a platform with on-screen controls.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    private var player: PlayerNode!
    private var lastUpdateTime: TimeInterval = 0

    // HUD buttons (children of camera so they stay fixed)
    private var leftButton: SKShapeNode!
    private var rightButton: SKShapeNode!
    private var jumpButton: SKShapeNode!
    private var attackButton: SKShapeNode!
    private var healthHUD: HealthHUD?
    /// Currently alive enemies. Populated at level start, drained as enemies die.
    private var enemies: [EnemyNode] = []
    /// Level configuration: factory closures that create a fresh, positioned
    /// enemy each time the level (re)starts.
    private var enemySpawns: [() -> EnemyNode] = []
    private var damageCooldown: TimeInterval = 0

    private var isGameOver: Bool = false
    /// Becomes true once the player has hit the ground after dying and the
    /// game-over overlay has been shown. Until then, physics keeps running
    /// so the corpse falls naturally.
    private var isShowingGameOverOverlay: Bool = false
    private var gameOverOverlay: SKNode?
    private var isPaused_: Bool = false
    private var pauseOverlay: SKNode?
    private var pauseButton: SKShapeNode!
    private var damageVignette: SKShapeNode?
    private var staff: StaffNode!

    // Level configuration
    /// 1 = base level (enemies, NPC, collectibles, portal). 2+ = empty placeholder.
    /// Assign before `didMove(to:)` runs.
    var levelIndex: Int = 1
    /// Max HP the player starts the level with. Carried across portal transitions.
    var startingMaxHP: Int = 2

    // Collectibles & portal
    private var collectibleHUD: CollectibleHUD?
    private var collectibles: [CollectibleNode] = []
    private var collectibleCount: Int = 0
    private let requiredCollectibles: Int = 4
    private var portal: PortalNode?
    private var isPortalTransitioning: Bool = false
    private var portalOverlay: PortalTransitionOverlay?

    // Boss arena (level 2)
    private var boss: BossNode?
    private var barrier: BarrierNode?
    private var bossAI: BossAIController?
    private var arenaCenterX: CGFloat = 0
    private var arenaLockTriggerX: CGFloat = 0
    private var isCameraLocked: Bool = false
    private var isVictoryCinematic: Bool = false
    private var isVictoryShown: Bool = false
    private var winOverlay: SKNode?

    // NPC & dialogue
    private var npc: NPCNode?
    private var dialogueBox: DialogueBox?
    private var interactionDwellTime: TimeInterval = 0
    /// Seconds the player must stand still inside the NPC's range to trigger dialogue.
    private let interactionRequiredDwell: TimeInterval = 0.5
    private var isInDialogue: Bool = false
    /// After a dialogue closes, the player must leave the NPC's range before
    /// another dialogue can be triggered. This flag tracks that "rearm" state.
    private var npcReadyToTrigger: Bool = true
    private let playerSpawn = CGPoint(x: 120, y: 200)


    // World horizontal bounds. The camera stops scrolling when its edge hits these,
    // and physical walls prevent the player from leaving.
    private var worldMinX: CGFloat = 0
    private var worldMaxX: CGFloat = 0

    /// Size of the area actually visible on screen, in scene coordinates.
    /// Accounts for aspectFill cropping.
    private var visibleSize: CGSize = .zero

    private func computeVisibleSize(for view: SKView) -> CGSize {
        let viewSize = view.bounds.size
        guard viewSize.width > 0, viewSize.height > 0 else { return size }
        switch scaleMode {
        case .aspectFill:
            let scale = max(viewSize.width / size.width, viewSize.height / size.height)
            return CGSize(width: viewSize.width / scale, height: viewSize.height / scale)
        case .aspectFit:
            let scale = min(viewSize.width / size.width, viewSize.height / size.height)
            return CGSize(width: viewSize.width / scale, height: viewSize.height / scale)
        default:
            return size
        }
    }

    // Track which finger is on which button
    private var leftTouch: UITouch?
    private var rightTouch: UITouch?

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.55, green: 0.78, blue: 0.95, alpha: 1.0)

        physicsWorld.gravity = CGVector(dx: 0, dy: -9.0)
        physicsWorld.contactDelegate = self

        visibleSize = computeVisibleSize(for: view)

        // World extends from -size.width to 2*size.width (matches the ground).
        worldMinX = -size.width
        worldMaxX = size.width * 2

        setupCamera()
        setupGround()
        setupWorldBounds()
        setupPlayer()
        if levelIndex == 1 {
            setupPlatforms()
            setupEnemies()
            setupNPC()
            setupCollectibles()
            setupPortal()
        } else if levelIndex == 2 {
            setupBossArena()
        }
        setupHUD()
        // Apply the level's starting max HP after the HUD exists, so the
        // callback that updates the HUD doesn't crash on a nil reference.
        player.setMaxHP(startingMaxHP)
    }

    private static let cameraZoom: CGFloat = 0.65  // <1 = zoom in

    private func setupCamera() {
        let cam = SKCameraNode()
        cam.position = CGPoint(x: size.width / 2, y: size.height / 2)
        cam.setScale(GameScene.cameraZoom)
        addChild(cam)
        camera = cam
    }

    private func setupGround() {
        let ground = SKShapeNode(rectOf: CGSize(width: size.width * 3, height: 40))
        ground.fillColor = SKColor(red: 0.30, green: 0.55, blue: 0.20, alpha: 1.0)
        ground.strokeColor = .clear
        ground.position = CGPoint(x: size.width / 2, y: 40)
        ground.name = "ground"

        let body = SKPhysicsBody(rectangleOf: CGSize(width: size.width * 3, height: 40))
        body.isDynamic = false
        body.friction = 0.0
        body.categoryBitMask = PhysicsCategory.ground
        body.collisionBitMask = PhysicsCategory.player | PhysicsCategory.enemy
        body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.enemy
        ground.physicsBody = body
        addChild(ground)
    }

    private func setupPlatforms() {
        addPlatform(at: CGPoint(x: size.width * 0.30, y: 200), size: CGSize(width: 180, height: 24))
        addPlatform(at: CGPoint(x: size.width * 0.55, y: 320), size: CGSize(width: 180, height: 24))
        addPlatform(at: CGPoint(x: size.width * 0.80, y: 220), size: CGSize(width: 180, height: 24))
    }

    private func addPlatform(at position: CGPoint, size: CGSize) {
        let p = SKShapeNode(rectOf: size)
        p.fillColor = SKColor(red: 0.40, green: 0.30, blue: 0.20, alpha: 1.0)
        p.strokeColor = .clear
        p.position = position
        p.name = "platform"

        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic = false
        body.friction = 0.0
        body.categoryBitMask = PhysicsCategory.platform
        body.collisionBitMask = PhysicsCategory.player
        body.contactTestBitMask = PhysicsCategory.player
        p.physicsBody = body
        addChild(p)
    }

    private func setupPlayer() {
        player = PlayerNode()
        player.position = playerSpawn
        player.onHealthChanged = { [weak self] current, max in
            // healthHUD is created later in setupHUD; guard with optional chaining.
            self?.healthHUD?.setHealth(current: current, max: max)
            if current <= 0 { self?.triggerGameOver() }
        }
        addChild(player)

        staff = StaffNode()
        staff.position = player.position
        addChild(staff)
    }

    private func setupWorldBounds() {
        let wallThickness: CGFloat = 20
        let wallHeight: CGFloat = size.height * 4
        addWall(x: worldMinX - wallThickness / 2, thickness: wallThickness, height: wallHeight)
        addWall(x: worldMaxX + wallThickness / 2, thickness: wallThickness, height: wallHeight)
    }

    private func addWall(x: CGFloat, thickness: CGFloat, height: CGFloat) {
        let wall = SKNode()
        wall.position = CGPoint(x: x, y: height / 2)
        let body = SKPhysicsBody(rectangleOf: CGSize(width: thickness, height: height))
        body.isDynamic = false
        body.friction = 0.0
        body.categoryBitMask = PhysicsCategory.wall
        body.collisionBitMask = PhysicsCategory.player
        body.contactTestBitMask = 0
        wall.physicsBody = body
        addChild(wall)
    }

    /// Places the level's single NPC. Edit this to change the NPC for a level —
    /// pass the dialogue lines, a name and a portrait image (any PNG bundled in
    /// the project, e.g. `face_normal`).
    private func setupNPC() {
        let n = NPCNode(
            name: "Old Sage",
            portraitImageName: "face_normal",
            lines: [
                "Olá, viajante. Há muito não via gente por estas bandas.",
                "Cuidado com as criaturas que vagueiam pelas plataformas.",
                "Boa sorte na tua jornada."
            ]
        )
        n.position = CGPoint(x: size.width * 0.18, y: 60)
        addChild(n)
        npc = n
    }

    private func setupEnemies() {
        // Level enemy roster — each entry is a factory that builds and positions
        // one enemy. Add / remove entries to design the level.
        let groundY: CGFloat = 60
        enemySpawns = [
            // 1. Slime patrols on the ground.
            { [unowned self] in
                let e = SlimeEnemy(minX: size.width * 0.40, maxX: size.width * 0.70)
                e.position = CGPoint(x: size.width * 0.40, y: groundY)
                return e
            },
            // 2. Flyer patrols mid-air.
            { [unowned self] in
                let e = FlyerEnemy(minX: size.width * 0.30, maxX: size.width * 0.65)
                e.position = CGPoint(x: size.width * 0.30, y: 260)
                return e
            },
            // 3. Jumper hops 2 forward / 2 back.
            { [unowned self] in
                let e = JumperEnemy()
                e.position = CGPoint(x: size.width * 0.85, y: groundY + 40)
                return e
            },
            // 4. Chaser idles until the player gets close.
            { [unowned self] in
                let e = SnakeEnemy(detectRange: 260)
                e.position = CGPoint(x: size.width * 1.20, y: groundY)
                return e
            },
            // 5. Immortal hazard — slow and unkillable.
            { [unowned self] in
                let e = ImmortalEnemy(minX: size.width * 1.40, maxX: size.width * 1.70)
                e.position = CGPoint(x: size.width * 1.40, y: groundY)
                return e
            },
            // 6. Flower pot trap — hovers above the middle platform, drops
            // when the player walks across it.
            { [unowned self] in
                let e = FlowerPotEnemy()
                // Middle platform is at (size.width * 0.55, 320). Place the
                // pot directly above it with enough clearance for the player.
                e.position = CGPoint(x: size.width * 0.55, y: 330)
                return e
            },
        ]
        spawnEnemies()
    }

    // MARK: - Collectibles & portal

    private func setupCollectibles() {
        // Spawn the level's 4 collectibles. Positions roughly correspond to
        // the existing platforms (size.width * 0.30/0.55/0.80 at y=200/320/220)
        // plus one on the ground further along.
        let positions: [CGPoint] = [
            CGPoint(x: size.width * 0.30, y: 224),
            CGPoint(x: size.width * 0.55, y: 344),
            CGPoint(x: size.width * 0.80, y: 244),
            CGPoint(x: size.width * 1.30, y: 60),
        ]
        collectibles.removeAll()
        for (i, p) in positions.enumerated() {
            let c = CollectibleNode(at: p, pieceIndex: i + 1)
            addChild(c)
            collectibles.append(c)
        }
    }

    private func setupPortal() {
        let p = PortalNode(at: CGPoint(x: size.width * 1.85, y: 60))
        p.setCounter(collected: collectibleCount, required: requiredCollectibles)
        addChild(p)
        portal = p
    }

    // MARK: - Boss arena (level 2)

    private func setupBossArena() {
        let groundTopY: CGFloat = 60

        // 3×3 grid laid out so the camera lock view shows: grid → barrier → boss.
        // Cell size and column offsets are chosen so the whole arena fits
        // inside the locked viewport (~886 scene units wide at cameraZoom 0.65).
        let cellW: CGFloat = 110
        let cellH: CGFloat = 110

        // Arena anchored at 3/4 of the world width.
        arenaCenterX = size.width * 0.75

        // Columns centered to the LEFT of the arena center (player side).
        let rightX: CGFloat = arenaCenterX - 40    // rightmost grid column
        let midX: CGFloat = rightX - cellW
        let leftX: CGFloat = rightX - 2 * cellW

        // Rows: row 0 = bottom (ground level), row 1 = mid, row 2 = top.
        let row0Y = groundTopY + cellH / 2
        let row1Y = row0Y + cellH
        let row2Y = row1Y + cellH

        let gridCells: [[CGPoint]] = [
            [CGPoint(x: leftX, y: row0Y), CGPoint(x: midX, y: row0Y), CGPoint(x: rightX, y: row0Y)],
            [CGPoint(x: leftX, y: row1Y), CGPoint(x: midX, y: row1Y), CGPoint(x: rightX, y: row1Y)],
            [CGPoint(x: leftX, y: row2Y), CGPoint(x: midX, y: row2Y), CGPoint(x: rightX, y: row2Y)],
        ]

        // Platforms (footing for the player to reach upper rows). Position
        // their TOP at the row's bottom so the player stands inside the cell.
        // Pattern follows the sketch: top-row middle, mid-row left, mid-row right.
        let platformWidth: CGFloat = cellW - 20
        let platformH: CGFloat = 18
        // Row 1 (mid) — left column platform
        addPlatform(at: CGPoint(x: leftX, y: row1Y - cellH / 2 - platformH / 2),
                    size: CGSize(width: platformWidth, height: platformH))
        // Row 1 (mid) — right column platform
        addPlatform(at: CGPoint(x: rightX, y: row1Y - cellH / 2 - platformH / 2),
                    size: CGSize(width: platformWidth, height: platformH))
        // Row 2 (top) — middle column platform
        addPlatform(at: CGPoint(x: midX, y: row2Y - cellH / 2 - platformH / 2),
                    size: CGSize(width: platformWidth, height: platformH))

        // Barrier just to the right of the rightmost column.
        let barrierX = rightX + cellW / 2 + 16
        let b = BarrierNode(at: CGPoint(x: barrierX, y: groundTopY))
        b.onBroken = { [weak self] in
            self?.barrier = nil
        }
        addChild(b)
        barrier = b

        // Boss body to the right of the barrier.
        let bossX = barrierX + 130
        let bo = BossNode(at: CGPoint(x: bossX, y: groundTopY))
        bo.onDefeat = { [weak self] in
            self?.triggerVictory()
        }
        addChild(bo)
        boss = bo

        // Lock trigger sits just before the leftmost column so the camera
        // snaps into the arena once the player is about to enter the grid.
        arenaLockTriggerX = leftX - cellW / 2 - 40

        // Spin up the AI.
        let ai = BossAIController(
            gridCells: gridCells,
            cellSize: CGSize(width: cellW, height: cellH),
            scene: self
        )
        ai.start()
        bossAI = ai
    }

    /// Removes any existing enemy nodes and spawns a fresh set from `enemySpawns`.
    private func spawnEnemies() {
        for enemy in enemies { enemy.removeFromParent() }
        enemies.removeAll()

        for makeEnemy in enemySpawns {
            let enemy = makeEnemy()
            enemy.onDeath = { [weak self] dead in
                self?.enemies.removeAll { $0 === dead }
            }
            addChild(enemy)
            enemies.append(enemy)
        }
    }

    /// Repopulates the enemy list, resets the player, and clears the game-over state.
    func restartLevel() {
        spawnEnemies()

        // Reset player
        player.position = playerSpawn
        player.physicsBody?.velocity = .zero
        player.stopMoving()
        player.resetHealth()

        // Reset collectibles & portal (only present on level 1).
        if levelIndex == 1 {
            for c in collectibles { c.removeFromParent() }
            collectibles.removeAll()
            portal?.removeFromParent()
            portal = nil
            collectibleCount = 0
            collectibleHUD?.reset()
            setupCollectibles()
            setupPortal()
        }

        // Reset boss arena (only present on level 2).
        if levelIndex == 2 {
            bossAI?.stop()
            bossAI = nil
            barrier?.removeFromParent()
            barrier = nil
            boss?.removeFromParent()
            boss = nil
            // Remove any in-flight attack hitboxes.
            children.compactMap { $0 as? BossAttackHitbox }.forEach { $0.removeFromParent() }
            isCameraLocked = false
            isVictoryCinematic = false
            isVictoryShown = false
            winOverlay?.removeFromParent()
            winOverlay = nil
            setupBossArena()
        }

        // Clear damage cooldown & overlay
        damageCooldown = 0
        gameOverOverlay?.removeFromParent()
        gameOverOverlay = nil
        isGameOver = false
        isShowingGameOverOverlay = false
        removeAction(forKey: "gameOverFallback")
        physicsWorld.speed = 1
        lastUpdateTime = 0
        leftTouch = nil
        rightTouch = nil
    }

    private func triggerGameOver() {
        guard !isGameOver else { return }
        isGameOver = true
        player.stopMoving()
        // Zero only the horizontal velocity so gravity can still pull the
        // corpse down to the ground. The overlay is shown later, in update(_:),
        // once the player has landed (or hit a hard timeout).
        if let body = player.physicsBody {
            body.velocity = CGVector(dx: 0, dy: body.velocity.dy)
        }
        // Hard fallback: if the player never lands (e.g. dies off-map), show
        // the overlay after a few seconds regardless.
        run(.sequence([
            .wait(forDuration: 3.0),
            .run { [weak self] in self?.presentGameOverIfNeeded() }
        ]), withKey: "gameOverFallback")
    }

    private func presentGameOverIfNeeded() {
        guard isGameOver, !isShowingGameOverOverlay else { return }
        isShowingGameOverOverlay = true
        removeAction(forKey: "gameOverFallback")
        player.stopMoving()
        player.physicsBody?.velocity = .zero
        physicsWorld.speed = 0
        showGameOverOverlay()
    }

    private func showGameOverOverlay() {
        guard let cam = camera else { return }
        let overlay = SKNode()
        overlay.zPosition = 2000

        let halfW = visibleSize.width / 2
        let halfH = visibleSize.height / 2

        let bg = SKShapeNode(rectOf: CGSize(width: visibleSize.width, height: visibleSize.height))
        bg.fillColor = SKColor(white: 0, alpha: 0.6)
        bg.strokeColor = .clear
        overlay.addChild(bg)

        let label = SKLabelNode(text: "GAME OVER")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 96
        label.fontColor = .white
        label.position = CGPoint(x: 0, y: 60)
        overlay.addChild(label)

        overlay.addChild(makeOverlayButton(
            name: "restartButton", label: "RESTART", position: CGPoint(x: 0, y: -80)
        ))
        overlay.addChild(makeOverlayButton(
            name: "menuButton", label: "MAIN MENU", position: CGPoint(x: 0, y: -190)
        ))

        _ = halfW; _ = halfH
        cam.addChild(overlay)
        gameOverOverlay = overlay
    }

    private func makeOverlayButton(name: String, label: String, position: CGPoint) -> SKShapeNode {
        let button = SKShapeNode(rectOf: CGSize(width: 360, height: 90), cornerRadius: 12)
        button.name = name
        button.fillColor = SKColor(white: 1.0, alpha: 0.2)
        button.strokeColor = SKColor(white: 1.0, alpha: 0.8)
        button.lineWidth = 3
        button.position = position
        let text = SKLabelNode(text: label)
        text.fontName = "AvenirNext-Bold"
        text.fontSize = 44
        text.fontColor = .white
        text.verticalAlignmentMode = .center
        button.addChild(text)
        return button
    }

    // MARK: - NPC interaction

    private func updateNPCInteraction(deltaTime: TimeInterval) {
        guard let npc = npc, !isInDialogue else { return }
        let dx = player.position.x - npc.position.x
        let inRange = abs(dx) <= npc.interactionRange

        // Re-arm once the player walks out of range.
        if !inRange { npcReadyToTrigger = true }

        let stopped = abs(player.physicsBody?.velocity.dx ?? 0) < 5
        if inRange && stopped && npcReadyToTrigger {
            interactionDwellTime += deltaTime
            if interactionDwellTime >= interactionRequiredDwell {
                openDialogue(with: npc)
            }
        } else {
            interactionDwellTime = 0
        }
    }

    private func openDialogue(with npc: NPCNode) {
        guard let cam = camera, !isInDialogue else { return }
        isInDialogue = true
        interactionDwellTime = 0
        player.stopMoving()
        leftTouch = nil
        rightTouch = nil

        let box = DialogueBox(visibleSize: visibleSize)
        box.show(name: npc.displayName, portraitImageName: npc.portraitImageName, lines: npc.lines)
        box.onClose = { [weak self] in
            self?.dialogueBox = nil
            self?.isInDialogue = false
            // Block re-triggering until the player leaves the NPC's range.
            self?.npcReadyToTrigger = false
            self?.lastUpdateTime = 0   // avoid dt spike
        }
        cam.addChild(box)
        dialogueBox = box
    }

    private func pauseGame() {
        guard !isPaused_, !isGameOver else { return }
        isPaused_ = true
        player.stopMoving()
        leftTouch = nil
        rightTouch = nil
        physicsWorld.speed = 0
        showPauseOverlay()
    }

    private func resumeGame() {
        guard isPaused_ else { return }
        isPaused_ = false
        physicsWorld.speed = 1
        pauseOverlay?.removeFromParent()
        pauseOverlay = nil
        lastUpdateTime = 0   // avoid a big dt spike on resume
    }

    private func showPauseOverlay() {
        guard let cam = camera else { return }
        let overlay = SKNode()
        overlay.zPosition = 2000

        let bg = SKShapeNode(rectOf: CGSize(width: visibleSize.width, height: visibleSize.height))
        bg.fillColor = SKColor(white: 0, alpha: 0.6)
        bg.strokeColor = .clear
        overlay.addChild(bg)

        let label = SKLabelNode(text: "PAUSED")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 96
        label.fontColor = .white
        label.position = CGPoint(x: 0, y: 140)
        overlay.addChild(label)

        overlay.addChild(makeOverlayButton(
            name: "resumeButton", label: "RESUME", position: CGPoint(x: 0, y: 30)
        ))
        overlay.addChild(makeOverlayButton(
            name: "restartButton", label: "RESTART", position: CGPoint(x: 0, y: -80)
        ))
        overlay.addChild(makeOverlayButton(
            name: "menuButton", label: "MAIN MENU", position: CGPoint(x: 0, y: -190)
        ))

        cam.addChild(overlay)
        pauseOverlay = overlay
    }

    private func flashDamageVignette() {
        guard let cam = camera else { return }
        damageVignette?.removeFromParent()

        let vignette = SKShapeNode(rectOf: visibleSize)
        vignette.fillColor = .clear
        vignette.strokeColor = SKColor.red
        vignette.lineWidth = 80
        vignette.alpha = 0
        vignette.zPosition = 1500
        cam.addChild(vignette)
        damageVignette = vignette

        vignette.run(.sequence([
            .fadeAlpha(to: 0.7, duration: 0.06),
            .fadeAlpha(to: 0.0, duration: 0.25),
            .removeFromParent()
        ]))
    }

    private func goToMainMenu() {
        guard let view = self.view else { return }
        let menu = MenuScene(size: size)
        menu.scaleMode = scaleMode
        view.presentScene(menu, transition: .fade(withDuration: 0.4))
    }

    // MARK: - Victory (boss defeated)

    private func triggerVictory() {
        guard !isVictoryCinematic, !isVictoryShown else { return }
        isVictoryCinematic = true
        bossAI?.stop()
        player.stopMoving()
        player.physicsBody?.velocity = .zero
        physicsWorld.speed = 0

        guard let cam = camera else { return }
        let overlay = BossDefeatOverlay(visibleSize: visibleSize)
        overlay.onComplete = { [weak self] in
            self?.isVictoryCinematic = false
            self?.showWinOverlay()
        }
        cam.addChild(overlay)
        overlay.present()
    }

    private func showWinOverlay() {
        guard !isVictoryShown, let cam = camera else { return }
        isVictoryShown = true
        let overlay = SKNode()
        overlay.zPosition = 2000

        let bg = SKShapeNode(rectOf: CGSize(width: visibleSize.width, height: visibleSize.height))
        bg.fillColor = SKColor(white: 0, alpha: 0.65)
        bg.strokeColor = .clear
        overlay.addChild(bg)

        let label = SKLabelNode(text: "YOU WIN")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 96
        label.fontColor = .yellow
        label.position = CGPoint(x: 0, y: 60)
        overlay.addChild(label)

        overlay.addChild(makeOverlayButton(
            name: "restartButton", label: "RESTART", position: CGPoint(x: 0, y: -80)
        ))
        overlay.addChild(makeOverlayButton(
            name: "menuButton", label: "MAIN MENU", position: CGPoint(x: 0, y: -190)
        ))

        cam.addChild(overlay)
        winOverlay = overlay
    }

    // MARK: - HUD

    private func setupHUD() {
        guard let cam = camera else { return }

        let halfW = visibleSize.width / 2
        let halfH = visibleSize.height / 2
        let bottomY = -halfH + 140

        // U+FE0E (VARIATION SELECTOR-15) forces the arrow glyphs to render in
        // text style instead of color-emoji style, so left/right match the
        // monochrome look of the jump triangle.
        leftButton = makeButton(label: "◀\u{FE0E}", position: CGPoint(x: -halfW + 110, y: bottomY))
        leftButton.name = "leftButton"
        cam.addChild(leftButton)

        rightButton = makeButton(label: "▶\u{FE0E}", position: CGPoint(x: -halfW + 290, y: bottomY))
        rightButton.name = "rightButton"
        cam.addChild(rightButton)

        attackButton = makeButton(label: "✦", position: CGPoint(x: halfW - 130, y: bottomY))
        attackButton.name = "attackButton"
        cam.addChild(attackButton)

        jumpButton = makeButton(label: "▲\u{FE0E}", position: CGPoint(x: halfW - 310, y: bottomY))
        jumpButton.name = "jumpButton"
        cam.addChild(jumpButton)

        pauseButton = SKShapeNode(rectOf: CGSize(width: 70, height: 70), cornerRadius: 10)
        pauseButton.name = "pauseButton"
        pauseButton.fillColor = SKColor(white: 1.0, alpha: 0.25)
        pauseButton.strokeColor = SKColor(white: 1.0, alpha: 0.6)
        pauseButton.lineWidth = 2
        pauseButton.position = CGPoint(x: halfW - 110, y: halfH - 60)
        let pauseLabel = SKLabelNode(text: "II")
        pauseLabel.fontName = "AvenirNext-Bold"
        pauseLabel.fontSize = 36
        pauseLabel.fontColor = .white
        pauseLabel.verticalAlignmentMode = .center
        pauseLabel.horizontalAlignmentMode = .center
        pauseButton.addChild(pauseLabel)
        cam.addChild(pauseButton)

        let h = HealthHUD()
        h.position = CGPoint(x: -halfW + 80, y: halfH - 60)
        h.zPosition = 1000
        cam.addChild(h)
        h.setHealth(current: player.hitPoints, max: player.maxHitPoints)
        healthHUD = h

        let c = CollectibleHUD()
        c.position = CGPoint(
            x: -halfW + 80,
            y: halfH - 100   // ~40 px below the health HUD
        )
        c.zPosition = 1000
        cam.addChild(c)
        c.build(maxCount: requiredCollectibles)
        collectibleHUD = c
    }

    private static let buttonRadius: CGFloat = 80

    private func makeButton(label: String, position: CGPoint) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: GameScene.buttonRadius)
        node.fillColor = SKColor(white: 1.0, alpha: 0.25)
        node.strokeColor = SKColor(white: 1.0, alpha: 0.6)
        node.lineWidth = 2
        node.position = position
        node.zPosition = 1000

        let text = SKLabelNode(text: label)
        text.fontName = "AvenirNext-Bold"
        text.fontSize = 56
        text.fontColor = .white
        text.verticalAlignmentMode = .center
        text.horizontalAlignmentMode = .center
        node.addChild(text)
        return node
    }

    /// Returns the name of the HUD button hit by `point` (in camera space),
    /// using a strict circular hit test so the hitbox matches the visible button.
    private func hudButtonHit(at point: CGPoint) -> String? {
        let buttons: [SKShapeNode?] = [leftButton, rightButton, jumpButton, attackButton]
        for case let button? in buttons {
            let dx = point.x - button.position.x
            let dy = point.y - button.position.y
            if (dx * dx + dy * dy) <= GameScene.buttonRadius * GameScene.buttonRadius {
                return button.name
            }
        }
        return nil
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isPortalTransitioning || isVictoryCinematic {
            // Swallow all input while a transition overlay is showing.
            return
        }
        if isVictoryShown {
            for touch in touches {
                guard let overlay = winOverlay else { return }
                let location = touch.location(in: overlay)
                if let restart = overlay.childNode(withName: "restartButton") as? SKShapeNode,
                   restart.contains(location) {
                    overlay.removeFromParent()
                    winOverlay = nil
                    isVictoryShown = false
                    restartLevel()
                    return
                }
                if let menu = overlay.childNode(withName: "menuButton") as? SKShapeNode,
                   menu.contains(location) {
                    goToMainMenu()
                    return
                }
            }
            return
        }
        if isInDialogue {
            // Any tap advances the dialogue.
            dialogueBox?.advance()
            return
        }
        if isPaused_ {
            for touch in touches {
                guard let overlay = pauseOverlay else { return }
                let location = touch.location(in: overlay)
                if let resume = overlay.childNode(withName: "resumeButton") as? SKShapeNode,
                   resume.contains(location) {
                    resumeGame()
                    return
                }
                if let restart = overlay.childNode(withName: "restartButton") as? SKShapeNode,
                   restart.contains(location) {
                    resumeGame()
                    restartLevel()
                    return
                }
                if let menu = overlay.childNode(withName: "menuButton") as? SKShapeNode,
                   menu.contains(location) {
                    goToMainMenu()
                    return
                }
            }
            return
        }
        if isGameOver {
            for touch in touches {
                guard let overlay = gameOverOverlay else { return }
                let location = touch.location(in: overlay)
                if let restart = overlay.childNode(withName: "restartButton") as? SKShapeNode,
                   restart.contains(location) {
                    restartLevel()
                    return
                }
                if let menu = overlay.childNode(withName: "menuButton") as? SKShapeNode,
                   menu.contains(location) {
                    goToMainMenu()
                    return
                }
            }
            return
        }
        for touch in touches {
            guard let cam = camera else { return }
            let location = touch.location(in: cam)

            if pauseButton.contains(location) {
                pauseGame()
                return
            }

            let buttonName = hudButtonHit(at: location)

            switch buttonName {
            case "leftButton":
                leftTouch = touch
                player.startMoving(direction: -1)
            case "rightButton":
                rightTouch = touch
                player.startMoving(direction: 1)
            case "jumpButton":
                player.jump()
            case "attackButton":
                if let hitbox = player.performAttack() {
                    addChild(hitbox)
                }
            default:
                break
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if touch === leftTouch {
                leftTouch = nil
                if rightTouch != nil { player.startMoving(direction: 1) }
                else { player.stopMoving() }
            } else if touch === rightTouch {
                rightTouch = nil
                if leftTouch != nil { player.startMoving(direction: -1) }
                else { player.stopMoving() }
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    // MARK: - Update loop

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        if isPaused_ || isPortalTransitioning { return }
        if isShowingGameOverOverlay { return }
        if isVictoryCinematic || isVictoryShown { return }

        // Lock the camera once the player crosses the arena trigger (level 2).
        if levelIndex == 2, !isCameraLocked, player.position.x >= arenaLockTriggerX {
            isCameraLocked = true
            // Drop an invisible wall behind the player so they can't backtrack
            // out of the arena. Only added now (not in setupBossArena) so it
            // doesn't block the player from walking in in the first place.
            addWall(x: arenaLockTriggerX - 30, thickness: 20, height: size.height * 4)
        }

        // During dying (isGameOver == true, overlay not yet shown), we still
        // let player physics and the camera run so the corpse falls naturally
        // — but enemies, NPC interaction and dialogue logic stay paused.
        player.update(deltaTime: dt)
        staff.update(deltaTime: dt, playerPosition: player.position, facingRight: player.facingRight)
        staff.isHidden = player.isAttacking

        if !isGameOver && !isInDialogue {
            for enemy in enemies { enemy.update(deltaTime: dt, playerPosition: player.position) }
            if damageCooldown > 0 { damageCooldown -= dt }
            updateNPCInteraction(deltaTime: dt)
        }

        // Trigger the overlay once the dying player has touched the ground.
        if isGameOver, !isShowingGameOverOverlay, player.isGrounded {
            presentGameOverIfNeeded()
        }

        if let cam = camera {
            let halfVisW = visibleSize.width * GameScene.cameraZoom / 2
            let halfVisH = visibleSize.height * GameScene.cameraZoom / 2
            let minCamX = worldMinX + halfVisW
            let maxCamX = worldMaxX - halfVisW
            let targetX: CGFloat
            if isCameraLocked {
                targetX = arenaCenterX
            } else {
                targetX = min(max(player.position.x, minCamX), maxCamX)
            }
            cam.position = CGPoint(x: targetX, y: max(player.position.y, halfVisH))
        }
    }

    // MARK: - Contact delegate

    func didBegin(_ contact: SKPhysicsContact) {
        let mask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if mask == (PhysicsCategory.player | PhysicsCategory.platform)
            || mask == (PhysicsCategory.player | PhysicsCategory.ground) {
            // Only count as "ground" if the player is landing on top of it
            let playerBody = contact.bodyA.categoryBitMask == PhysicsCategory.player ? contact.bodyA : contact.bodyB
            let otherBody  = contact.bodyA.categoryBitMask == PhysicsCategory.player ? contact.bodyB : contact.bodyA
            if let playerNode = playerBody.node, let platformNode = otherBody.node,
               playerNode.position.y > platformNode.position.y {
                player.didBeginContactWithPlatform()
            }
        } else if mask == (PhysicsCategory.enemy | PhysicsCategory.ground) {
            // A flower pot (or other dropping enemy) hits the floor → land it.
            let enemyBody = contact.bodyA.categoryBitMask == PhysicsCategory.enemy ? contact.bodyA : contact.bodyB
            if let pot = enemyBody.node as? FlowerPotEnemy {
                pot.land()
            }
        } else if mask == (PhysicsCategory.player | PhysicsCategory.enemy) {
            if damageCooldown <= 0 {
                let enemyBody = contact.bodyA.categoryBitMask == PhysicsCategory.enemy ? contact.bodyA : contact.bodyB
                let knockbackDir: CGFloat = {
                    if let enemyNode = enemyBody.node {
                        return player.position.x >= enemyNode.position.x ? 1 : -1
                    }
                    return player.facingRight ? -1 : 1
                }()
                player.applyHitKnockback(direction: knockbackDir)
                player.takeDamage()
                flashDamageVignette()
                damageCooldown = 1.0
            }
        } else if mask == (PhysicsCategory.projectile | PhysicsCategory.enemy) {
            let enemyBody = contact.bodyA.categoryBitMask == PhysicsCategory.enemy ? contact.bodyA : contact.bodyB
            if let enemy = enemyBody.node as? EnemyNode {
                enemy.takeDamage()
            }
        } else if mask == (PhysicsCategory.player | PhysicsCategory.collectible) {
            let pickupBody = contact.bodyA.categoryBitMask == PhysicsCategory.collectible ? contact.bodyA : contact.bodyB
            if let pickup = pickupBody.node as? CollectibleNode {
                handleCollect(pickup)
            }
        } else if mask == (PhysicsCategory.player | PhysicsCategory.portal) {
            if let p = portal, p.isUnlocked, !isPortalTransitioning {
                triggerPortalTransition()
            }
        } else if mask == (PhysicsCategory.player | PhysicsCategory.bossAttack) {
            if damageCooldown <= 0 {
                player.applyHitKnockback(direction: player.facingRight ? -1 : 1)
                player.takeDamage()
                flashDamageVignette()
                damageCooldown = 1.0
            }
        } else if mask == (PhysicsCategory.projectile | PhysicsCategory.bossAttack) {
            // Find the hit live cell. Walk up the node tree to the
            // BossAttackHitbox container to read its `kind`.
            let attackBody = contact.bodyA.categoryBitMask == PhysicsCategory.bossAttack ? contact.bodyA : contact.bodyB
            var node = attackBody.node
            while node != nil, !(node is BossAttackHitbox) { node = node?.parent }
            if let container = node as? BossAttackHitbox, container.kind == .vertical {
                barrier?.registerHit()
            }
        } else if mask == (PhysicsCategory.projectile | PhysicsCategory.bossBody) {
            // Only counts after the barrier is gone.
            if barrier == nil { boss?.takeFinalHit() }
        }
    }

    // MARK: - Collectibles / portal handlers

    private func handleCollect(_ pickup: CollectibleNode) {
        // Avoid double-counting if SpriteKit fires the contact twice.
        guard collectibles.contains(where: { $0 === pickup }) else { return }
        collectibles.removeAll { $0 === pickup }
        pickup.collect()
        collectibleCount += 1
        collectibleHUD?.collect(pieceIndex: pickup.pieceIndex)
        portal?.setCounter(collected: collectibleCount, required: requiredCollectibles)
        player.heal(1)
        if collectibleCount >= requiredCollectibles {
            portal?.isUnlocked = true
        }
    }

    private func triggerPortalTransition() {
        isPortalTransitioning = true
        // Reward: +1 max HP carried into the next level.
        player.increaseMaxHP(by: 1)
        // Freeze gameplay while the overlay is up.
        player.stopMoving()
        player.physicsBody?.velocity = .zero
        leftTouch = nil
        rightTouch = nil
        physicsWorld.speed = 0

        guard let cam = camera else { return }
        let overlay = PortalTransitionOverlay(visibleSize: visibleSize)
        let nextMaxHP = player.maxHitPoints
        let currentSize = size
        let currentScaleMode = scaleMode
        overlay.onComplete = { [weak self] in
            guard let self = self, let view = self.view else { return }
            let next = GameScene(size: currentSize)
            next.scaleMode = currentScaleMode
            next.levelIndex = self.levelIndex + 1
            next.startingMaxHP = nextMaxHP
            view.presentScene(next, transition: .fade(withDuration: 0.5))
        }
        cam.addChild(overlay)
        portalOverlay = overlay
        overlay.present()
    }

    func didEnd(_ contact: SKPhysicsContact) {
        let mask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if mask == (PhysicsCategory.player | PhysicsCategory.platform)
            || mask == (PhysicsCategory.player | PhysicsCategory.ground) {
            player.didEndContactWithPlatform()
        }
    }
}
