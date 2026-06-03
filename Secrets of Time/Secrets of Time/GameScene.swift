//
//  GameScene.swift
//  Secrets of Time
//
//  Cena principal do jogo. Gere o ciclo de jogo completo: carregamento de níveis,
//  câmara, HUD, áudio, entrada táctil, detecção de colisões e transições de cena.
//  Implementa SKPhysicsContactDelegate para reagir a contactos entre corpos físicos.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    // MARK: - Level management
    var currentLevel = 1
    /// Max HP the player starts the level with. Passed from scene to scene so
    /// the extra hearts earned through portals survive level transitions.
    var startingMaxHP: Int = 2

    private var levelData: Level!
    private var player: PlayerNode!
    private var lastUpdateTime: TimeInterval = 0

    // MARK: - Portal / collectible
    private var portal: PortalNode?
    private var collectible: CollectibleNode?
    private var collectiblesCollected = 0
    private let collectiblesRequired = 1
    private var isTransitioning = false

    // MARK: - Boss
    private var boss: BossNode?
    private var barrier: BarrierNode?
    private var bossAI: BossAIController?
    private var bossZoomTriggered = false
    private var bossZoomTriggerX: CGFloat = 0
    private var bossLockedCameraX: CGFloat = 0
    private var tentacleHitsCount = 0
    private let tentacleHitsRequired = 5

    // MARK: - HUD
    private var leftButton: SKShapeNode!
    private var rightButton: SKShapeNode!
    private var jumpButton: SKShapeNode!
    private var attackButton: SKShapeNode!
    private var healthHUD: HealthHUD!

    // MARK: - Enemies
    private var enemies: [EnemyNode] = []
    private var enemyProjectiles: [EnemyProjectile] = []
    private var damageCooldown: TimeInterval = 0

    // MARK: - State
    private var isGameOver: Bool = false
    private var gameOverOverlay: SKNode?
    private var isPaused_: Bool = false
    private var pauseOverlay: SKNode?
    private var pauseButton: SKShapeNode!
    private var damageVignette: SKShapeNode?
    private var staff: StaffNode!

    // MARK: - NPC & dialogue
    private var npc: NPCNode?
    private var dialogueBox: DialogueBox?
    private var interactionDwellTime: TimeInterval = 0
    private let interactionRequiredDwell: TimeInterval = 0.5
    private var isInDialogue: Bool = false
    private var npcReadyToTrigger: Bool = true

    // MARK: - World
    private var worldMinX: CGFloat = 0
    private var worldMaxX: CGFloat = 0
    private var visibleSize: CGSize = .zero

    // MARK: - Touch
    private var leftTouch: UITouch?
    private var rightTouch: UITouch?

    // MARK: - Audio
    // Música gerida pelo AudioManager (singleton) — não há node local de música.

    // MARK: - Camera
    private static let cameraZoom: CGFloat = 0.65

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

    // MARK: - didMove

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.55, green: 0.78, blue: 0.95, alpha: 1.0)

        let background: String
        switch currentLevel {
        case 1:  background = "forest_bg"
        case 2:  background = "beachbg"
        case 3:  background = "aut_bg"
        case 4:  background = "winter_bg"
        default: background = "bg_boss"
        }

        let bgTexture = SKTexture(imageNamed: background)
        bgTexture.filteringMode = .nearest
        let tileWidth = bgTexture.size().width
        let numTiles = Int(size.width * 3 / tileWidth) + 2
        for i in 0..<numTiles {
            let tile = SKSpriteNode(texture: bgTexture)
            tile.size = CGSize(width: tileWidth, height: size.height)
            tile.anchorPoint = CGPoint(x: 0, y: 0)
            tile.position = CGPoint(x: tileWidth * CGFloat(i) - size.width, y: 0)
            tile.zPosition = -200
            addChild(tile)
        }

        physicsWorld.gravity = CGVector(dx: 0, dy: -9.0)
        physicsWorld.contactDelegate = self

        visibleSize = computeVisibleSize(for: view)

        worldMinX = -size.width
        worldMaxX = size.width * 2

        setupCamera()
        setupGround()
        setupWorldBounds()
        setupPlayer()
        loadLevel(currentLevel)
        setupHUD()
    }

    // MARK: - Camera

    private func setupCamera() {
        let cam = SKCameraNode()
        cam.position = CGPoint(x: size.width / 2, y: size.height / 2)
        cam.setScale(GameScene.cameraZoom)
        addChild(cam)
        camera = cam
    }

    // MARK: - Ground / Platforms

    private func setupGround() {
        let ground_level: String
        switch currentLevel {
        case 1: ground_level = "floor"
        case 2: ground_level = "sand"
        case 3: ground_level = "floor"
        case 4: ground_level = "groundwinter"
        default: ground_level = "platform_boss"
        }
        let texture = SKTexture(imageNamed: ground_level)
        texture.filteringMode = .nearest
        let tileWidth = texture.size().width
        let numTiles = Int(size.width * 3 / tileWidth) + 2
        for i in 0..<numTiles {
            let tile = SKSpriteNode(texture: texture)
            tile.anchorPoint = CGPoint(x: 0, y: 0)
            tile.position = CGPoint(x: tileWidth * CGFloat(i) - size.width, y: -20)
            tile.zPosition = 0
            addChild(tile)
        }

        let ground = SKNode()
        ground.position = CGPoint(x: size.width / 2, y: 10)
        ground.name = "ground"
        let body = SKPhysicsBody(rectangleOf: CGSize(width: size.width * 3, height: 60))
        body.isDynamic = false
        body.friction = 0.0
        body.categoryBitMask = PhysicsCategory.ground
        body.collisionBitMask = PhysicsCategory.player | PhysicsCategory.enemy
        body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.enemy
        ground.physicsBody = body
        addChild(ground)
    }

    private func addPlatform(at position: CGPoint, size: CGSize) {
        let platform: String
        switch currentLevel {
        case 1:  platform = "platformspring"
        case 2:  platform = "platform_beach"
        case 3:  platform = "platformspring"
        case 4:  platform = "platformwinter"
        default: platform = "platform_boss"
        }
        let p = SKSpriteNode(imageNamed: platform)
        p.texture?.filteringMode = .nearest
        p.position = position
        p.name = "platform"

        let body = SKPhysicsBody(rectangleOf: p.size)
        body.isDynamic = false
        body.friction = 0.0
        body.categoryBitMask = PhysicsCategory.platform
        body.collisionBitMask = PhysicsCategory.player | PhysicsCategory.enemy
        body.contactTestBitMask = PhysicsCategory.player
        p.physicsBody = body
        addChild(p)
    }

    // MARK: - Player

    private func setupPlayer() {
        player = PlayerNode()
        player.onHealthChanged = { [weak self] current, max in
            self?.healthHUD?.setHealth(current: current, max: max)
            if current <= 0 { self?.triggerGameOver() }
        }
        addChild(player)

        staff = StaffNode()
        addChild(staff)
    }

    // MARK: - World bounds

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

    // MARK: - Level loading

    private func loadLevel(_ level: Int) {
        // Clean up previous level entities
        enemies.forEach { $0.removeFromParent() }
        enemies.removeAll()
        npc?.removeFromParent()
        npc = nil
        portal?.removeFromParent(); portal = nil
        collectible?.removeFromParent(); collectible = nil
        collectiblesCollected = 0
        boss?.removeFromParent(); boss = nil
        barrier?.removeFromParent(); barrier = nil
        bossAI?.stop(); bossAI = nil
        bossZoomTriggered = false
        childNode(withName: "cameraTrigger")?.removeFromParent()

        currentLevel = level

        switch level {
        case 1: levelData = Levels.level1(size: size)
        case 2: levelData = Levels.level2(size: size)
        case 3: levelData = Levels.level3(size: size)
        case 4: levelData = Levels.level4(size: size)
        default: levelData = Levels.level5(size: size)
        }

        player.position = levelData.playerSpawn
        player.physicsBody?.velocity = .zero
        player.stopMoving()
        player.setMaxHP(startingMaxHP)   // restore carried-over max HP, refill current HP
        damageCooldown = 0.8

        for p in levelData.platforms {
            addPlatform(at: p.0, size: p.1)
        }

        for (imageName, position) in levelData.decorations {
            let sprite = SKSpriteNode(imageNamed: imageName)
            sprite.texture?.filteringMode = .nearest
            sprite.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            sprite.position = position
            sprite.zPosition = -150   // behind ground/platforms/enemies, just in front of background (-200)
            addChild(sprite)
        }

        enemies = levelData.enemies.map { factory in
            let e = factory()
            e.onDeath = { [weak self] dead in
                self?.enemies.removeAll { $0 === dead }
                self?.run(SKAction.playSoundFileNamed("enemy-kill.mp3", waitForCompletion: false))
            }
            // Wire turret projectile spawning
            if let turret = e as? TurretEnemy {
                turret.onFireProjectile = { [weak self] proj in
                    self?.addChild(proj)
                    self?.enemyProjectiles.append(proj)
                    self?.playSound("explosion_3.mp3", volume: 0.35)
                }
            }
            return e
        }
        enemies.forEach { addChild($0) }

        if let npcNode = levelData.npc, let npcPos = levelData.npcPosition {
            npcNode.position = npcPos
            addChild(npcNode)
            npc = npcNode
        }

        // Collectible
        if let pos = levelData.collectiblePosition {
            let c = CollectibleNode(at: pos, pieceIndex: currentLevel)
            addChild(c)
            collectible = c
        }

        // Portal
        if let pos = levelData.portalPosition {
            let p = PortalNode(at: pos)
            p.setCounter(collected: 0, required: collectiblesRequired)
            addChild(p)
            portal = p
        }

        // Boss arena (level 5)
        if level == 5 {
            setupBoss()
        }
    }

    // MARK: - Boss setup

    private func setupBoss() {
        tentacleHitsCount = 0

        // -- Trigger (visible orange line) --
        bossZoomTriggerX = 260
        bossLockedCameraX = 590
        let trigger = SKShapeNode(rectOf: CGSize(width: 8, height: 700))
        trigger.fillColor = SKColor.orange.withAlphaComponent(0.5)
        trigger.strokeColor = .orange
        trigger.lineWidth = 2
        trigger.position = CGPoint(x: bossZoomTriggerX, y: 350)
        trigger.name = "cameraTrigger"
        trigger.zPosition = 90
        addChild(trigger)

        // -- Barrier --
        let barrierNode = BarrierNode(at: CGPoint(x: 700, y: 0))
        addChild(barrierNode)
        barrier = barrierNode

        // -- Boss --
        let bossNode = BossNode(at: CGPoint(x: 920, y: 60))
        bossNode.onDefeat = { [weak self] in
            self?.bossAI?.stop()
            self?.showBossVictory()
        }
        addChild(bossNode)
        boss = bossNode

        // -- 3×3 grid filling the player side of the arena --
        // Columns 105, 315, 525 (width 210 each → covers x=0..630)
        // Rows aligned with where the player actually stands:
        //   row0 = ground (~y=40), row1 = platform y=180 (top=192), row2 = platform y=350 (top=362)
        let cols: [CGFloat] = [105, 315, 525]
        let rows: [CGFloat] = [90, 215, 380]
        let cellSize = CGSize(width: 210, height: 120)
        let grid: [[CGPoint]] = rows.map { y in cols.map { x in CGPoint(x: x, y: y) } }

        let ai = BossAIController(gridCells: grid, cellSize: cellSize, scene: self)
        bossAI = ai
        // AI starts only when the player crosses the camera trigger
    }

    // MARK: - Level transition

    private func transitionToNextLevel() {
        guard let view = view, let cam = camera else { return }
        isTransitioning = true
        player.stopMoving()
        leftTouch = nil; rightTouch = nil
        physicsWorld.speed = 0   // congela inimigos e física durante a transição

        run(SKAction.playSoundFileNamed("upgrade_levelup.mp3", waitForCompletion: false))

        // Recompensa: +1 HP máximo por nível completado
        player.increaseMaxHP(by: 1)
        let nextMaxHP = player.maxHitPoints   // guardado APÓS o aumento para passar à cena seguinte
        run(SKAction.playSoundFileNamed("woosh.mp3", waitForCompletion: false))

        // Mostra overlay com as peças do puzzle recolhidas até agora
        let overlay = PortalTransitionOverlay(visibleSize: visibleSize, levelsCompleted: currentLevel)
        overlay.alpha = 0
        cam.addChild(overlay)
        overlay.run(.fadeIn(withDuration: 0.3))

        // Nível 4 tem mais tempo de espera porque o puzzle fica completo
        let holdDuration: TimeInterval = currentLevel == 4 ? 3.5 : 2.5
        run(.sequence([
            .wait(forDuration: holdDuration),
            .run { [weak self] in  // [weak self] evita retain cycle na closure
                guard let self = self else { return }
                let next = self.currentLevel + 1
                if next > 5 {
                    self.goToMainMenu()
                    return
                }
                let scene = GameScene(size: self.size)
                scene.scaleMode = self.scaleMode
                scene.currentLevel = next
                scene.startingMaxHP = nextMaxHP
                view.presentScene(scene, transition: SKTransition.fade(with: .black, duration: 0.8))
            }
        ]))
    }

    // MARK: - Boss victory

    private func showBossVictory() {
        guard let cam = camera else { return }
        run(SKAction.playSoundFileNamed("meow.mp3", waitForCompletion: false))
        let overlay = BossDefeatOverlay(visibleSize: visibleSize)
        overlay.onComplete = { [weak self] in
            self?.goToMainMenu()
        }
        cam.addChild(overlay)
        overlay.present()
    }

    // MARK: - Game over / restart

    private func triggerGameOver() {
        guard !isGameOver else { return }
        isGameOver = true
        player.stopMoving()
        player.physicsBody?.velocity = .zero
        run(SKAction.playSoundFileNamed("player-death.mp3", waitForCompletion: false))
        showGameOverOverlay()
        physicsWorld.speed = 0
        self.speed = 0          // stop boss AI actions after overlay is queued
    }

    private func showGameOverOverlay() {
        guard let cam = camera else { return }
        let overlay = SKNode()
        overlay.zPosition = 2000

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

    func restartLevel() {
        guard let view = view else { return }
        let scene = GameScene(size: size)
        scene.scaleMode = scaleMode
        scene.currentLevel = currentLevel
        view.presentScene(scene, transition: SKTransition.fade(with: .black, duration: 0.3))
    }

    // MARK: - Pause

    private func pauseGame() {
        guard !isPaused_, !isGameOver else { return }
        isPaused_ = true
        player.stopMoving()
        leftTouch = nil; rightTouch = nil
        physicsWorld.speed = 0   // congela toda a física (inimigos, projéteis, etc.)
        self.speed = 0           // pausa todas as SKActions (IA do boss, animações)
        AudioManager.shared.pause()  // pausa a música de fundo (AVAudioPlayer)
        showPauseOverlay()
    }

    private func resumeGame() {
        guard isPaused_ else { return }
        isPaused_ = false
        physicsWorld.speed = 1
        self.speed = 1
        AudioManager.shared.resume()  // retoma a música a partir do ponto onde parou
        pauseOverlay?.removeFromParent()
        pauseOverlay = nil
        lastUpdateTime = 0  // evita delta-time gigante no primeiro frame após resume
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

    // MARK: - Damage vignette

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

    private func applyPlayerDamage(knockbackDir: CGFloat) {
        guard damageCooldown <= 0 else { return }
        player.applyHitKnockback(direction: knockbackDir)
        player.takeDamage()
        flashDamageVignette()
        run(SKAction.playSoundFileNamed("groan.mp3", waitForCompletion: false))
        damageCooldown = 1.0
    }

    // MARK: - Main menu

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

        leftButton = makeButton(label: "▲", labelRotation: .pi / 2,
                                position: CGPoint(x: -halfW + 110, y: bottomY))
        leftButton.name = "leftButton"
        cam.addChild(leftButton)

        rightButton = makeButton(label: "▲", labelRotation: -.pi / 2,
                                 position: CGPoint(x: -halfW + 290, y: bottomY))
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
        healthHUD.position = CGPoint(x: -halfW + 80, y: halfH - 60)
        healthHUD.zPosition = 1000
        cam.addChild(healthHUD)
        healthHUD.setHealth(current: player.hitPoints, max: player.maxHitPoints)
    }

    private static let buttonRadius: CGFloat = 80

    private func makeButton(label: String, labelRotation: CGFloat = 0,
                            position: CGPoint) -> SKShapeNode {
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
        text.zRotation = labelRotation
        node.addChild(text)
        return node
    }

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

    // MARK: - Audio

    /// Reproduz um efeito sonoro com volume controlado.
    /// Para sons a volume pleno usa SKAction (menor overhead).
    /// Para volume reduzido usa SKAudioNode temporário.
    private func playSound(_ name: String, volume: Float = 1.0) {
        if volume >= 0.99 {
            run(SKAction.playSoundFileNamed(name, waitForCompletion: false))
            return
        }
        let node = SKAudioNode(fileNamed: name)
        node.autoplayLooped = false
        node.isPositional = false
        addChild(node)
        node.run(.sequence([
            .changeVolume(to: volume, duration: 0),
            .play(),
            .wait(forDuration: 3.0),
            .removeFromParent()
        ]))
    }

    // MARK: - NPC interaction

    private func updateNPCInteraction(deltaTime: TimeInterval) {
        guard let npc = npc, !isInDialogue else { return }
        let dx = player.position.x - npc.position.x
        let inRange = abs(dx) <= npc.interactionRange

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
        leftTouch = nil; rightTouch = nil

        run(SKAction.playSoundFileNamed("chime.mp3", waitForCompletion: false))
        run(SKAction.playSoundFileNamed("meow.mp3", waitForCompletion: false))

        let box = DialogueBox(visibleSize: visibleSize)
        box.show(name: npc.displayName, portraitImageName: npc.portraitImageName, lines: npc.lines)
        box.onClose = { [weak self] in
            self?.dialogueBox = nil
            self?.isInDialogue = false
            self?.npcReadyToTrigger = false
            self?.lastUpdateTime = 0
        }
        cam.addChild(box)
        dialogueBox = box
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isInDialogue {
            dialogueBox?.advance()
            return
        }
        if isPaused_ {
            for touch in touches {
                guard let overlay = pauseOverlay else { return }
                let location = touch.location(in: overlay)
                if let resume = overlay.childNode(withName: "resumeButton") as? SKShapeNode,
                   resume.contains(location) { resumeGame(); return }
                if let restart = overlay.childNode(withName: "restartButton") as? SKShapeNode,
                   restart.contains(location) { resumeGame(); restartLevel(); return }
                if let menu = overlay.childNode(withName: "menuButton") as? SKShapeNode,
                   menu.contains(location) { goToMainMenu(); return }
            }
            return
        }
        if isGameOver {
            for touch in touches {
                guard let overlay = gameOverOverlay else { return }
                let location = touch.location(in: overlay)
                if let restart = overlay.childNode(withName: "restartButton") as? SKShapeNode,
                   restart.contains(location) { restartLevel(); return }
                if let menu = overlay.childNode(withName: "menuButton") as? SKShapeNode,
                   menu.contains(location) { goToMainMenu(); return }
            }
            return
        }
        for touch in touches {
            guard let cam = camera else { return }
            let location = touch.location(in: cam)

            if pauseButton.contains(location) { pauseGame(); return }

            switch hudButtonHit(at: location) {
            case "leftButton":
                leftTouch = touch
                player.startMoving(direction: -1)
            case "rightButton":
                rightTouch = touch
                player.startMoving(direction: 1)
            case "jumpButton":
                if player.jump() {
                    run(SKAction.playSoundFileNamed("jumping-sound-effect.mp3", waitForCompletion: false))
                }
            case "attackButton":
                if let hitbox = player.performAttack() { addChild(hitbox) }
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

        // Suspende todo o update lógico durante game over, pausa, diálogo ou transição de nível.
        if isGameOver || isPaused_ || isInDialogue || isTransitioning { return }

        player.update(deltaTime: dt)
        staff.update(deltaTime: dt, playerPosition: player.position, facingRight: player.facingRight)
        staff.isHidden = player.isAttacking

        for enemy in enemies {
            enemy.update(deltaTime: dt, playerPosition: player.position)
        }

        // Clean up expired projectiles
        enemyProjectiles.removeAll { $0.parent == nil }

        if damageCooldown > 0 { damageCooldown -= dt }

        updateNPCInteraction(deltaTime: dt)

        if let cam = camera {
            // Current scale used for half-visible calculations
            let currentScale = cam.xScale   // may differ from cameraZoom after boss lerp
            let halfVisH = visibleSize.height * currentScale / 2
            let camY = max(player.position.y, halfVisH)  // never show below y=0

            if currentLevel == 5, bossZoomTriggered {
                // Camera locked: X fixed on arena centre, Y follows player (clamped ≥ 0)
                cam.position = CGPoint(x: bossLockedCameraX, y: camY)
            } else {
                let halfVisW = visibleSize.width  * GameScene.cameraZoom / 2
                let halfVisH2 = visibleSize.height * GameScene.cameraZoom / 2
                let minCamX = worldMinX + halfVisW
                let maxCamX = worldMaxX - halfVisW
                let clampedX = min(max(player.position.x, minCamX), maxCamX)
                cam.position = CGPoint(x: clampedX, y: max(player.position.y, halfVisH2))
            }

            // Trigger: zoom out + lock camera + start boss AI
            if currentLevel == 5, !bossZoomTriggered,
               player.position.x >= bossZoomTriggerX {
                bossZoomTriggered = true
                cam.run(.scale(to: 1.15, duration: 1.5), withKey: "bossZoom")
                cam.run(.moveTo(x: bossLockedCameraX, duration: 1.5), withKey: "bossMove")
                bossAI?.start()
                run(.sequence([
                    .wait(forDuration: 0.8),
                    .playSoundFileNamed("meow.mp3", waitForCompletion: false)
                ]))
            }
        }
    }

    // MARK: - Contact delegate

    func didBegin(_ contact: SKPhysicsContact) {
        let mask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        // -- Platform / ground landing --
        if mask == (PhysicsCategory.player | PhysicsCategory.platform)
            || mask == (PhysicsCategory.player | PhysicsCategory.ground) {
            let playerBody = contact.bodyA.categoryBitMask == PhysicsCategory.player
                ? contact.bodyA : contact.bodyB
            let otherBody  = contact.bodyA.categoryBitMask == PhysicsCategory.player
                ? contact.bodyB : contact.bodyA
            if let pNode = playerBody.node, let oNode = otherBody.node,
               pNode.position.y > oNode.position.y {
                player.didBeginContactWithPlatform()
            }

        // -- FlowerPot lands --
        } else if mask == (PhysicsCategory.enemy | PhysicsCategory.ground)
               || mask == (PhysicsCategory.enemy | PhysicsCategory.platform) {
            let enemyBody = contact.bodyA.categoryBitMask == PhysicsCategory.enemy
                ? contact.bodyA : contact.bodyB
            if let pot = enemyBody.node as? FlowerPotEnemy { pot.land() }

        // -- Player ↔ Enemy --
        } else if mask == (PhysicsCategory.player | PhysicsCategory.enemy) {
            let enemyBody = contact.bodyA.categoryBitMask == PhysicsCategory.enemy
                ? contact.bodyA : contact.bodyB
            let dir: CGFloat = {
                if let eNode = enemyBody.node {
                    return player.position.x >= eNode.position.x ? 1 : -1
                }
                return player.facingRight ? -1 : 1
            }()
            applyPlayerDamage(knockbackDir: dir)

        // -- Player ↔ Enemy projectile --
        } else if mask == (PhysicsCategory.player | PhysicsCategory.enemyProjectile) {
            let projBody = contact.bodyA.categoryBitMask == PhysicsCategory.enemyProjectile
                ? contact.bodyA : contact.bodyB
            let dir: CGFloat = player.facingRight ? -1 : 1
            applyPlayerDamage(knockbackDir: dir)
            projBody.node?.removeFromParent()

        // -- Player ↔ Collectible --
        } else if mask == (PhysicsCategory.player | PhysicsCategory.collectible) {
            guard collectible != nil else { return }
            collectible?.collect()
            collectible = nil
            collectiblesCollected += 1
            player.heal(1)
            portal?.setCounter(collected: collectiblesCollected, required: collectiblesRequired)
            if collectiblesCollected >= collectiblesRequired {
                portal?.isUnlocked = true
                run(SKAction.playSoundFileNamed("upgrade_levelup.mp3", waitForCompletion: false))
            } else {
                run(SKAction.playSoundFileNamed("coin-catch.mp3", waitForCompletion: false))
            }

        // -- Player ↔ Portal --
        } else if mask == (PhysicsCategory.player | PhysicsCategory.portal) {
            guard portal?.isUnlocked == true, !isTransitioning else { return }
            transitionToNextLevel()

        // -- Player attack ↔ Enemy --
        } else if mask == (PhysicsCategory.projectile | PhysicsCategory.enemy) {
            let enemyBody = contact.bodyA.categoryBitMask == PhysicsCategory.enemy
                ? contact.bodyA : contact.bodyB
            if let enemy = enemyBody.node as? EnemyNode {
                enemy.takeDamage()
            }

        // -- Player attack ↔ Boss attack (tentacle/pata) → counts toward barrier --
        } else if mask == (PhysicsCategory.projectile | PhysicsCategory.bossAttack) {
            // O tentáculo/pata NÃO é destruído — continua ativo no ecrã.
            // Apenas contamos o acerto para efeitos de progressão da barreira.
            tentacleHitsCount += 1
            if tentacleHitsCount >= tentacleHitsRequired {
                tentacleHitsCount = 0
                barrier?.registerHit()
                barrier?.registerHit()
                barrier?.registerHit()  // 3 hits = break immediately
            }

        // -- Player attack ↔ Boss body --
        } else if mask == (PhysicsCategory.projectile | PhysicsCategory.bossBody) {
            if barrier?.isBroken ?? true {
                boss?.takeFinalHit()
            }

        // -- Player ↔ Boss attack --
        } else if mask == (PhysicsCategory.player | PhysicsCategory.bossAttack) {
            applyPlayerDamage(knockbackDir: player.facingRight ? -1 : 1)

        // -- Player ↔ Boss body (direct contact) --
        } else if mask == (PhysicsCategory.player | PhysicsCategory.bossBody) {
            applyPlayerDamage(knockbackDir: player.position.x < (boss?.position.x ?? 0) ? -1 : 1)
        }
    }

    func didEnd(_ contact: SKPhysicsContact) {
        let mask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if mask == (PhysicsCategory.player | PhysicsCategory.platform)
            || mask == (PhysicsCategory.player | PhysicsCategory.ground) {
            // Mirror the begin check: only count contacts where the player landed
            // on TOP of the surface. Without this, walking into the side of a
            // platform decrements groundContacts even though begin never incremented
            // it, driving the counter to 0 and locking the player in falling state.
            let playerBody = contact.bodyA.categoryBitMask == PhysicsCategory.player
                ? contact.bodyA : contact.bodyB
            let otherBody  = contact.bodyA.categoryBitMask == PhysicsCategory.player
                ? contact.bodyB : contact.bodyA
            if let pNode = playerBody.node, let oNode = otherBody.node,
               pNode.position.y >= oNode.position.y {
                player.didEndContactWithPlatform()
            }
        }
    }
}
