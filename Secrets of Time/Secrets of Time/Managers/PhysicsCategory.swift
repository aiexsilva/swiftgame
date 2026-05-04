import Foundation

struct PhysicsCategory {
    static let none:       UInt32 = 0
    static let player:     UInt32 = 0b1        // 1
    static let enemy:      UInt32 = 0b10       // 2
    static let projectile: UInt32 = 0b100      // 4
    static let artifact:   UInt32 = 0b1000     // 8
    static let platform:   UInt32 = 0b10000    // 16
    static let teleport:   UInt32 = 0b100000   // 32
    static let all:        UInt32 = UInt32.max
}
