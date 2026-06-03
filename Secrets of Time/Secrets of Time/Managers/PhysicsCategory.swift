//
//  PhysicsCategory.swift
//  Secrets of Time
//
//  Defines the physics bitmask categories used throughout the game.
//  Each category is a unique power-of-2 bit so they can be combined
//  with bitwise OR to build collisionBitMask / contactTestBitMask values.
//

import Foundation

/// Physics layer identifiers for SpriteKit contact and collision detection.
/// A physics body's `categoryBitMask` declares what it IS.
/// Its `collisionBitMask` lists what physically pushes it.
/// Its `contactTestBitMask` lists what triggers `didBegin(_:)` callbacks.
struct PhysicsCategory {
    static let none:           UInt32 = 0
    static let player:         UInt32 = 0b1              // 1   – the player character
    static let enemy:          UInt32 = 0b10             // 2   – all regular enemies
    static let projectile:     UInt32 = 0b100            // 4   – player attack hitbox
    static let artifact:       UInt32 = 0b1000           // 8   – (reserved)
    static let platform:       UInt32 = 0b10000          // 16  – elevated platforms
    static let teleport:       UInt32 = 0b100000         // 32  – (reserved)
    static let wall:           UInt32 = 0b1000000        // 64  – world boundary walls
    static let ground:         UInt32 = 0b10000000       // 128 – main floor
    static let collectible:    UInt32 = 0b100000000      // 256 – puzzle piece pickups
    static let portal:         UInt32 = 0b1000000000     // 512 – level-exit portal
    static let bossAttack:     UInt32 = 0b10000000000    // 1024 – boss attack hitboxes
    static let barrier:        UInt32 = 0b100000000000   // 2048 – boss protective barrier
    static let bossBody:       UInt32 = 0b1000000000000  // 4096 – boss main body
    static let enemyProjectile:UInt32 = 0b10000000000000 // 8192 – projectiles fired by enemies
    static let all:            UInt32 = UInt32.max
}
