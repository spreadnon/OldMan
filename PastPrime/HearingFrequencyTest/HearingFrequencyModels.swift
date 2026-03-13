//
//  HearingFrequencyModels.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import Foundation

enum HearingFrequencyEndReason: String, Codable {
    case stoppedByUser
    case timeout
    case cancelled
}

struct HearingFrequencySessionResult: Codable, Identifiable, Hashable {
    let id: UUID
    let detectedHz: Int?
    let durationMs: Int
    let startHz: Int
    let endHz: Int
    let outputRoute: String
    let endReason: HearingFrequencyEndReason
    let createdAt: Date

    init(
        id: UUID = UUID(),
        detectedHz: Int?,
        durationMs: Int,
        startHz: Int,
        endHz: Int,
        outputRoute: String,
        endReason: HearingFrequencyEndReason,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.detectedHz = detectedHz
        self.durationMs = durationMs
        self.startHz = startHz
        self.endHz = endHz
        self.outputRoute = outputRoute
        self.endReason = endReason
        self.createdAt = createdAt
    }
}

enum HearingFrequencyLevel: String, Codable, CaseIterable {
    case veryHigh
    case high
    case medium
    case low

    static func from(detectedHz: Int) -> HearingFrequencyLevel {
        if detectedHz >= 15_000 { return .veryHigh }
        if detectedHz >= 10_000 { return .high }
        if detectedHz >= 8_000 { return .medium }
        return .low
    }

    var title: String {
        switch self {
        case .veryHigh:
            return "很高频率"
        case .high:
            return "较高频率"
        case .medium:
            return "中等频率"
        case .low:
            return "较低频率"
        }
    }

    var ageReferenceText: String {
        switch self {
        case .veryHigh:
            return "≈ 20–30 岁"
        case .high:
            return "≈ 40 岁"
        case .medium:
            return "≈ 40–60 岁（参考）"
        case .low:
            return "≈ 60+ 岁"
        }
    }
}

struct HearingFrequencyConfig: Hashable {
    var startHz: Double = 18_000
    var endHz: Double = 2_000
    var durationSec: Double = 15
    var amplitude: Double = 0.12
    var hapticsEnabled: Bool
    var showCurrentFrequency: Bool
}

enum HearingFrequencyDefaultsKeys {
    static let hapticsEnabled = "hearingFrequency.hapticsEnabled"
    static let showCurrentFrequency = "hearingFrequency.showCurrentFrequency"
    static let sessionsKey = "hearingFrequency.sessions.v1"
}

enum HearingFrequencyAgeReference {
    static let disclaimer = "仅供娱乐参考，受设备/疲劳/注意力等影响，不代表医学结论。"
    static let lines: [String] = [
        "> 15kHz ≈ 20–30 岁",
        "10–15kHz ≈ 40 岁",
        "< 8kHz ≈ 60+ 岁",
    ]
}

