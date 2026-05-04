import SpriteKit

class MenuScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.1, green: 0.15, blue: 0.25, alpha: 1.0)

        let title = SKLabelNode(text: "Secrets of Time")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 64
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.7)
        addChild(title)

        let playButton = SKLabelNode(text: "▶  Play")
        playButton.name = "playButton"
        playButton.fontName = "AvenirNext-DemiBold"
        playButton.fontSize = 40
        playButton.fontColor = .yellow
        playButton.position = CGPoint(x: size.width / 2, y: size.height * 0.4)
        addChild(playButton)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tapped = atPoint(location)

        if tapped.name == "playButton" {
            let scene = GameScene(size: size)
            scene.scaleMode = .aspectFill
            view?.presentScene(scene, transition: .fade(withDuration: 0.5))
        }
    }
}
