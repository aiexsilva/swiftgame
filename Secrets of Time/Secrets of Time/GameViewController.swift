//
//  GameViewController.swift
//  Secrets of Time
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let skView = self.view as? SKView else { return }

        let sceneSize = CGSize(width: 1366, height: 768)
        let scene = MenuScene(size: sceneSize)
        scene.scaleMode = .aspectFill

        skView.presentScene(scene)
        skView.ignoresSiblingOrder = true

        #if DEBUG
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsPhysics = true
        #endif
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
