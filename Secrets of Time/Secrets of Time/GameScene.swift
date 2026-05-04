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

    // Track which finger is on which button
    private var leftTouch: UITouch?
    private var rightTouch: UITouch?

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.55, green: 0.78, blue: 0.95, alpha: 1.0)

        physicsWorld.gravity = CGVector(dx: 0, dy: -9.0)
        physicsWorld.contactDelegate = self

        setupCamera()
        setupGround()
        setupPlatforms()
        setupPlayer()
        setupHUD()
    }

    private func setupCamera() {
        let cam = SKCameraNode()
        cam.position = CGPoint(x: size.width / 2, y: size.height / 2)
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
        player.position = CGPoint(x: 120, y: 200)
        addChild(player)
    }

    // MARK: - HUD

    private func setupHUD() {
        guard let cam = camera else { return }

        let bottomY = -size.height / 2 + 140

        leftButton = makeButton(label: "◀", position: CGPoint(x: -size.width / 2 + 110, y: bottomY))
        leftButton.name = "leftButton"
        cam.addChild(leftButton)

        rightButton = makeButton(label: "▶", position: CGPoint(x: -size.width / 2 + 290, y: bottomY))
        rightButton.name = "rightButton"
        cam.addChild(rightButton)

        attackButton = makeButton(label: "✦", position: CGPoint(x: size.width / 2 - 130, y: bottomY))
        attackButton.name = "attackButton"
        cam.addChild(attackButton)

        jumpButton = makeButton(label: "▲", position: CGPoint(x: size.width / 2 - 310, y: bottomY))
        jumpButton.name = "jumpButton"
        cam.addChild(jumpButton)
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
        for touch in touches {
            guard let cam = camera else { return }
            let location = touch.location(in: cam)
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

        player.update(deltaTime: dt)

        if let cam = camera {
            cam.position = CGPoint(x: player.position.x, y: max(player.position.y, size.height / 2))
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
        }
    }

    func didEnd(_ contact: SKPhysicsContact) {
        let mask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if mask == (PhysicsCategory.player | PhysicsCategory.platform) {
            player.didEndContactWithPlatform()
        }
    }
}
