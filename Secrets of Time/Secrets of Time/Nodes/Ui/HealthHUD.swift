//
//  HealthHUD.swift
//  Secrets of Time
//
//  HUD de saúde do jogador: mostra os pontos de vida como ícones de coração.
//  Corações ativos ficam totalmente visíveis; corações perdidos ficam translúcidos.
//  Deve ser adicionado como filho da câmara e atualizado via setHealth(current:max:).
//

import SpriteKit

/// HUD de corações que representa os pontos de vida do jogador.
class HealthHUD: SKNode {

    private let iconSize: CGFloat = 32
    private let spacing: CGFloat = 4
    private var hearts: [SKSpriteNode] = []

    private static let heartTexture: SKTexture = {
        let t = SKTexture(imageNamed: "Heart")
        t.filteringMode = .nearest   // crisp pixel art
        return t
    }()

    func build(maxHitPoints: Int) {
        removeAllChildren()
        hearts.removeAll()
        for i in 0..<maxHitPoints {
            let h = SKSpriteNode(texture: HealthHUD.heartTexture,
                                 size: CGSize(width: iconSize, height: iconSize))
            h.position = CGPoint(x: CGFloat(i) * (iconSize + spacing), y: 0)
            addChild(h)
            hearts.append(h)
        }
    }

    func setHealth(current: Int, max maxHP: Int) {
        if hearts.count != maxHP { build(maxHitPoints: maxHP) }
        for (i, heart) in hearts.enumerated() {
            // Lost HP slots stay visible but turn grey-tinted.
            heart.isHidden = false
            if i < current {
                heart.colorBlendFactor = 0
                heart.alpha = 1.0
            } else {
                // Clearly visible empty-slot heart: white tint, translucent
                heart.color = .white
                heart.colorBlendFactor = 0.0
                heart.alpha = 0.25
            }
        }
    }
}
