//
//  MemorySequenceModels.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import Foundation

enum MemorySequenceEndReason: String, Codable {
    case failed
    case cancelled
}

struct MemorySequenceSessionResult: Codable, Identifiable, Hashable {
    let id: UUID
    let bestItems: Int
    let startItems: Int
    let reachedItems: Int
    let endReason: MemorySequenceEndReason
    let createdAt: Date

    init(
        id: UUID = UUID(),
        bestItems: Int,
        startItems: Int,
        reachedItems: Int,
        endReason: MemorySequenceEndReason,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.bestItems = bestItems
        self.startItems = startItems
        self.reachedItems = reachedItems
        self.endReason = endReason
        self.createdAt = createdAt
    }
}

enum MemorySequenceLevel: String, Codable, CaseIterable {
    case strong
    case medium
    case weak

    static func from(bestItems: Int) -> MemorySequenceLevel {
        if bestItems >= 9 { return .strong }
        if bestItems >= 6 { return .medium }
        return .weak
    }

    var title: String {
        switch self {
        case .strong: return "强记忆"
        case .medium: return "中等记忆"
        case .weak: return "偏弱记忆"
        }
    }

    var ageReferenceText: String {
        switch self {
        case .strong: return "≈ 20–35 岁"
        case .medium: return "≈ 45–55 岁"
        case .weak: return "< 5 项偏老化"
        }
    }
}

struct MemorySequenceConfig: Hashable {
    var startItems: Int = 3
    var gridSide: Int = 3
    var flashMs: Int = 420
    var gapMs: Int = 180
    var hapticsEnabled: Bool
}

enum MemorySequenceDefaultsKeys {
    static let hapticsEnabled = "memorySequence.hapticsEnabled"
    static let sessionsKey = "memorySequence.sessions.v1"
}

enum MemorySequenceAgeReference {
    static let disclaimer = "仅供娱乐参考，受设备/疲劳/注意力等影响，不代表医学结论。"
    static let lines: [String] = [
        "记住 9+ 项 ≈ 20–35 岁",
        "记住 6–8 项 ≈ 45–55 岁",
        "< 5 项偏老化",
    ]
}

