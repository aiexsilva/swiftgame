//
//  GameViewController.swift
//  Secrets of Time
//
//  Ponto de entrada da app. Configura a sessão de áudio, arranca com o MenuScene
//  e força a orientação landscape.
//

import UIKit
import SpriteKit
import AVFoundation

/// Root UIViewController que apresenta o SKView com todas as cenas do jogo.
class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configura a sessão de áudio para reprodução: garante que os sons
        // tocam mesmo com o modo silencioso ativo no dispositivo.
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AVAudioSession error: \(error)")
        }

        // Inicia a música de fundo uma única vez; persiste entre níveis.
        AudioManager.shared.startMusic()

        guard let skView = self.view as? SKView else { return }

        // Fixed scene resolution: 1366×768 (landscape 4:3 iPad-like canvas)
        let sceneSize = CGSize(width: 1366, height: 768)
        let scene = MenuScene(size: sceneSize)
        scene.scaleMode = .aspectFill   // fills the screen, may crop slightly

        skView.presentScene(scene)
        skView.ignoresSiblingOrder = true  // rely on zPosition for draw order
    }

    /// Restrict to landscape so the game always renders in the expected orientation.
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
