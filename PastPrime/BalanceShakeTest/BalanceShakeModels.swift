//
//  BalanceShakeModels.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import Foundation

enum BalanceShakeEndReason: String, Codable {
    case wobble
    case reachedMaxTime
    case cancelled
}

struct BalanceShakeSessionResult: Codable, Identifiable, Hashable {
    let id: UUID
    let durationMs: Int
    let maxDeviationRad: Double
    let endReason: BalanceShakeEndReason
    let createdAt: Date

    init(
        id: UUID = UUID(),
        durationMs: Int,
        maxDeviationRad: Double,
        endReason: BalanceShakeEndReason,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.durationMs = durationMs
        self.maxDeviationRad = maxDeviationRad
        self.endReason = endReason
        self.createdAt = createdAt
    }
}

enum BalanceStabilityLevel: String, Codable, CaseIterable {
    case high
    case medium
    case low

    static func from(durationMs: Int) -> BalanceStabilityLevel {
        let seconds = Double(durationMs) / 1000.0
        if seconds >= 20 { return .high }
        if seconds >= 10 { return .medium }
        return .low
    }

    var title: String {
        switch self {
        case .high:
            return "高稳定性"
        case .medium:
            return "中等稳定性"
        case .low:
            return "低稳定性"
        }
    }

    var ageReferenceText: String {
        switch self {
        case .high:
            return "≈ 20–40 岁"
        case .medium:
            return "≈ 40–60 岁"
        case .low:
            return "≈ 60+ 岁"
        }
    }
}

struct BalanceShakeConfig: Hashable {
    var targetTimeSec: Int = 20
    var maxTimeSec: Int = 30

    var wobbleThresholdRad: Double = 0.35
    var wobbleGraceFrames: Int = 10

    var hapticsEnabled: Bool
    var soundEnabled: Bool
}

struct BalanceNormalizedOffset: Hashable {
    var x: Double
    var y: Double

    static let zero = BalanceNormalizedOffset(x: 0, y: 0)

    var magnitude: Double {
        (x * x + y * y).squareRoot()
    }

    func clamped(maxAbs: Double) -> BalanceNormalizedOffset {
        BalanceNormalizedOffset(
            x: min(max(x, -maxAbs), maxAbs),
            y: min(max(y, -maxAbs), maxAbs)
        )
    }

    func clampedToUnitCircle() -> BalanceNormalizedOffset {
        let m = magnitude
        guard m > 1 else { return self }
        return BalanceNormalizedOffset(x: x / m, y: y / m)
    }
}

enum BalanceShakeDefaultsKeys {
    static let hapticsEnabled = "balanceShake.hapticsEnabled"
    static let soundEnabled = "balanceShake.soundEnabled"
    static let sessionsKey = "balanceShake.sessions.v1"
}

enum BalanceShakeAgeReference {
    static let disclaimer = "仅供娱乐参考，受设备/疲劳/注意力等影响，不代表医学结论。"
    static let lines: [String] = [
        "高稳定性（>20 秒无大晃）≈ 20–40 岁",
        "中等稳定性 ≈ 40–60 岁",
        "低稳定性 ≈ 60+ 岁",
    ]
}

