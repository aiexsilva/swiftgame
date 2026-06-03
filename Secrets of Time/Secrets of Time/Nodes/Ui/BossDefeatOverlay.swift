//
//  BossDefeatOverlay.swift
//  Secrets of Time
//
//  Ecrã de vitória mostrado após o jogador derrotar o boss final.
//  Fundo preto com "YOU WIN" centrado. Apresenta o texto com fade-in,
//  aguarda alguns segundos e depois chama `onComplete` para regressar
//  ao menu principal.
//

import SpriteKit

/// Ecrã de vitória exibido após derrotar o boss. Chama `onComplete` ao terminar.
final class BossDefeatOverlay: SKNode {

    var onComplete: (() -> Void)?

    init(visibleSize: CGSize) {
        super.init()
        zPosition = 2600
        name = "bossDefeatOverlay"

        // Fundo preto que cobre todo o ecrã
        let bg = SKSpriteNode(color: .black, size: visibleSize)
        bg.position = .zero
        addChild(bg)

        // Título principal
        let title = SKLabelNode(text: "YOU WIN")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 120
        title.fontColor = .white
        title.verticalAlignmentMode = .center
        title.horizontalAlignmentMode = .center
        title.position = CGPoint(x: 0, y: 40)
        title.alpha = 0
        addChild(title)

        // Subtítulo
        let sub = SKLabelNode(text: "Parabéns! Derrotaste o boss final.")
        sub.fontName = "AvenirNext-DemiBold"
        sub.fontSize = 36
        sub.fontColor = SKColor(white: 1.0, alpha: 0.75)
        sub.verticalAlignmentMode = .center
        sub.horizontalAlignmentMode = .center
        sub.position = CGPoint(x: 0, y: -50)
        sub.alpha = 0
        addChild(sub)

        // Anima o texto para aparecer gradualmente
        let fadeIn = SKAction.fadeIn(withDuration: 1.2)
        title.run(.sequence([.wait(forDuration: 0.4), fadeIn]))
        sub.run(.sequence([.wait(forDuration: 0.9), fadeIn]))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present(holdDuration: TimeInterval = 5.0, fadeDuration: TimeInterval = 0.6) {
        run(.sequence([
            .wait(forDuration: holdDuration),
            .fadeOut(withDuration: fadeDuration),
            .run { [weak self] in self?.onComplete?() },
            .removeFromParent()
        ]))
    }
}
