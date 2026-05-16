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
    private var healthHUD: HealthHUD!
    /// Currently alive enemies. Populated at level start, drained as enemies die.
    private var enemies: [EnemyNode] = []
    /// Level configuration: factory closures that create a fresh, positioned
    /// enemy each time the level (re)starts.
    private var enemySpawns: [() -> EnemyNode] = []
    private var damageCooldown: TimeInterval = 0

    private var isGameOver: Bool = false
    private var gameOverOverlay: SKNode?
    private var isPaused_: Bool = false
    private var pauseOverlay: SKNode?
    private var pauseButton: SKShapeNode!
    private var damageVignette: SKShapeNode?
    private var staff: StaffNode!

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
        setupPlatforms()
        setupPlayer()
        setupEnemies()
        setupNPC()
        setupHUD()
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
        ground.name = "platform"

        let body = SKPhysicsBody(rectangleOf: CGSize(width: size.width * 3, height: 40))
        body.isDynamic = false
        body.friction = 0.0
        body.categoryBitMask = PhysicsCategory.platform
        body.collisionBitMask = PhysicsCategory.player
        body.contactTestBitMask = PhysicsCategory.player
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
            self?.healthHUD.setHealth(current: current, max: max)
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
                let e = ChaserEnemy(detectRange: 260)
                e.position = CGPoint(x: size.width * 1.20, y: groundY)
                return e
            },
            // 5. Immortal hazard — slow and unkillable.
            { [unowned self] in
                let e = ImmortalEnemy(minX: size.width * 1.40, maxX: size.width * 1.70)
                e.position = CGPoint(x: size.width * 1.40, y: groundY)
                return e
            },
        ]
        spawnEnemies()
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

        // Clear damage cooldown & overlay
        damageCooldown = 0
        gameOverOverlay?.removeFromParent()
        gameOverOverlay = nil
        isGameOver = false
        physicsWorld.speed = 1
        lastUpdateTime = 0
        leftTouch = nil
        rightTouch = nil
    }

    private func triggerGameOver() {
        guard !isGameOver else { return }
        isGameOver = true
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

    // MARK: - HUD

    private func setupHUD() {
        guard let cam = camera else { return }

        let halfW = visibleSize.width / 2
        let halfH = visibleSize.height / 2
        let bottomY = -halfH + 140

        leftButton = makeButton(label: "◀", position: CGPoint(x: -halfW + 110, y: bottomY))
        leftButton.name = "leftButton"
        cam.addChild(leftButton)

        rightButton = makeButton(label: "▶", position: CGPoint(x: -halfW + 290, y: bottomY))
        rightButton.name = "rightButton"
        cam.addChild(rightButton)

        attackButton = makeButton(label: "✦", position: CGPoint(x: halfW - 130, y: bottomY))
        attackButton.name = "attackButton"
        cam.addChild(attackButton)

        jumpButton = makeButton(label: "▲", position: CGPoint(x: halfW - 310, y: bottomY))
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

        healthHUD = HealthHUD()
        healthHUD.position = CGPoint(
            x: -halfW + 80,
            y: halfH - 60
        )
        healthHUD.zPosition = 1000
        cam.addChild(healthHUD)
        healthHUD.setHealth(current: player.hitPoints, max: player.maxHitPoints)
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

        if isGameOver || isPaused_ || isInDialogue { return }

        player.update(deltaTime: dt)
        staff.update(deltaTime: dt, playerPosition: player.position, facingRight: player.facingRight)
        staff.isHidden = player.isAttacking
        for enemy in enemies { enemy.update(deltaTime: dt, playerPosition: player.position) }
        if damageCooldown > 0 { damageCooldown -= dt }
        updateNPCInteraction(deltaTime: dt)

        if let cam = camera {
            let halfVisW = visibleSize.width * GameScene.cameraZoom / 2
            let halfVisH = visibleSize.height * GameScene.cameraZoom / 2
            let minCamX = worldMinX + halfVisW
            let maxCamX = worldMaxX - halfVisW
            let clampedX = min(max(player.position.x, minCamX), maxCamX)
            cam.position = CGPoint(x: clampedX, y: max(player.position.y, halfVisH))
        }
    }

    // MARK: - Contact delegate

    func didBegin(_ contact: SKPhysicsContact) {
        let mask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if mask == (PhysicsCategory.player | PhysicsCategory.platform) {
            // Only count as "ground" if the player is landing on top of the platform
            let playerBody = contact.bodyA.categoryBitMask == PhysicsCategory.player ? contact.bodyA : contact.bodyB
            let otherBody  = contact.bodyA.categoryBitMask == PhysicsCategory.player ? contact.bodyB : contact.bodyA
            if let playerNode = playerBody.node, let platformNode = otherBody.node,
               playerNode.position.y > platformNode.position.y {
                player.didBeginContactWithPlatform()
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
        }
    }

    func didEnd(_ contact: SKPhysicsContact) {
        let mask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if mask == (PhysicsCategory.player | PhysicsCategory.platform) {
            player.didEndContactWithPlatform()
        }
    }
}
