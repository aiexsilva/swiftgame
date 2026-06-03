//
//  PortalTransitionOverlay.swift
//  Secrets of Time
//
//  Full-screen overlay shown when the player passes through a level portal.
//  Displays the accumulated puzzle pieces (Puzzle1…N) in a 2×2 grid on a
//  dark background. After Level 4 (Winter) shows the completed puzzle image
//  instead. The overlay fades in while the next scene is already loading —
//  no waiting for the animation to fully complete.
//

import SpriteKit

/// Full-screen puzzle overlay shown during level transitions.
/// Add as a child of the camera so it covers the viewport.
final class PortalTransitionOverlay: SKNode {

    // MARK: - Init

    /// - Parameter levelsCompleted: How many levels the player has finished
    ///   (1 = left Spring, 4 = left Winter → full puzzle).
    init(visibleSize: CGSize, levelsCompleted: Int) {
        super.init()
        zPosition = 2600
        name = "portalOverlay"

        // Semi-opaque dark background so the puzzle pieces are clearly visible
        let bg = SKSpriteNode(color: SKColor(white: 0, alpha: 0.92), size: visibleSize)
        bg.position = .zero
        addChild(bg)

        buildPuzzle(levelsCompleted: min(max(levelsCompleted, 0), 4))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Puzzle grid

    /// Builds and places the puzzle content for the given completion state.
    private func buildPuzzle(levelsCompleted: Int) {
        guard levelsCompleted > 0 else { return }

        // After completing Winter (level 4) show the full assembled puzzle image
        if levelsCompleted >= 4 {
            let tex = SKTexture(imageNamed: "PuzzleCompleto")
            let img = SKSpriteNode(texture: tex, color: .clear,
                                   size: CGSize(width: 600, height: 400))
            img.position = .zero
            addChild(img)
            return
        }

        // Otherwise lay out the pieces collected so far in a 2×2 grid
        let pieceSize: CGFloat = 300
        let gap: CGFloat = 12

        // Slot positions: 1=top-left, 2=top-right, 3=bottom-right, 4=bottom-left
        let half = pieceSize / 2 + gap / 2
        let offsets: [CGPoint] = [
            CGPoint(x: -half, y:  half),   // 1 – top-left
            CGPoint(x:  half, y:  half),   // 2 – top-right
            CGPoint(x:  half, y: -half),   // 3 – bottom-right
            CGPoint(x: -half, y: -half)    // 4 – bottom-left
        ]

        for i in 1...levelsCompleted {
            let tex = SKTexture(imageNamed: "Puzzle\(i)")
            tex.filteringMode = .nearest
            let piece = SKSpriteNode(texture: tex, color: .clear,
                                     size: CGSize(width: pieceSize, height: pieceSize))
            piece.position = offsets[i - 1]
            addChild(piece)
        }
    }
}
