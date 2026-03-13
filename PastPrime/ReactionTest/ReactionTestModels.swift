//
//  ReactionTestModels.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import Foundation

enum TrialOutcome: String, Codable {
    case success
    case falseStart
    case timeout
    case cancelled
}

struct TrialResult: Codable, Identifiable, Hashable {
    let id: UUID
    let index: Int
    let outcome: TrialOutcome
    let reactionMs: Int?
    let waitDelayMs: Int?
    let timestamp: Date

    init(
        id: UUID = UUID(),
        index: Int,
        outcome: TrialOutcome,
        reactionMs: Int?,
        waitDelayMs: Int?,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.index = index
        self.outcome = outcome
        self.reactionMs = reactionMs
        self.waitDelayMs = waitDelayMs
        self.timestamp = timestamp
    }
}

struct SessionResult: Codable, Identifiable, Hashable {
    let id: UUID
    let trialCount: Int
    let trials: [TrialResult]
    let averageMs: Int?
    let bestMs: Int?
    let falseStartCount: Int
    let createdAt: Date

    init(
        id: UUID = UUID(),
        trialCount: Int,
        trials: [TrialResult],
        averageMs: Int?,
        bestMs: Int?,
        falseStartCount: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.trialCount = trialCount
        self.trials = trials
        self.averageMs = averageMs
        self.bestMs = bestMs
        self.falseStartCount = falseStartCount
        self.createdAt = createdAt
    }
}

struct ReactionTestConfig: Hashable {
    var trialCount: Int
    var delayRangeMs: ClosedRange<Int> = 1500...4500
    var tapCooldownMs: Int = 250
    var hapticsEnabled: Bool
    var soundEnabled: Bool
    var colorBlindModeEnabled: Bool

    init(
        trialCount: Int,
        delayRangeMs: ClosedRange<Int> = 1500...4500,
        tapCooldownMs: Int = 250,
        hapticsEnabled: Bool,
        soundEnabled: Bool,
        colorBlindModeEnabled: Bool
    ) {
        self.trialCount = trialCount
        self.delayRangeMs = delayRangeMs
        self.tapCooldownMs = tapCooldownMs
        self.hapticsEnabled = hapticsEnabled
        self.soundEnabled = soundEnabled
        self.colorBlindModeEnabled = colorBlindModeEnabled
    }
}

enum ReactionTestDefaultsKeys {
    static let trialCount = "reactionTest.trialCount"
    static let hapticsEnabled = "reactionTest.hapticsEnabled"
    static let soundEnabled = "reactionTest.soundEnabled"
    static let colorBlindModeEnabled = "reactionTest.colorBlindModeEnabled"
    static let sessionsKey = "reactionTest.sessions.v1"
}

enum ReactionTestAgeReference {
    static let disclaimer = "仅供娱乐参考，受设备/疲劳/注意力等影响，不代表医学结论。"
    static let lines: [String] = [
        "平均 < 220ms ≈ 20–30 岁",
        "平均 250–300ms ≈ 40 岁",
        "平均 > 350ms ≈ 60+ 岁",
    ]
}

