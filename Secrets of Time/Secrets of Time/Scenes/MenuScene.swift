//
//  MenuScene.swift
//  Secrets of Time
//
//  Main menu screen. Displays the MainMenu.png background image and starts
//  the game (Level 1) when the player taps anywhere on the screen.
//

import SpriteKit

/// Full-screen main menu. Tapping anywhere on the scene transitions to
/// the first level of the game with a fade.
class MenuScene: SKScene {

    override func didMove(to view: SKView) {
        // Load and display the main menu background image
        let tex = SKTexture(imageNamed: "MainMenu")
        tex.filteringMode = .nearest   // preserve pixel-art sharpness
        let bg = SKSpriteNode(texture: tex)
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.size = CGSize(width: size.width - 10, height: size.height - 100)
        bg.zPosition = 0
        addChild(bg)
    }

    /// Any touch on the screen starts the game from Level 1.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let scene = GameScene(size: size)
        scene.scaleMode = .aspectFill
        scene.currentLevel = 1
        view?.presentScene(scene, transition: .fade(withDuration: 0.5))
    }
}
