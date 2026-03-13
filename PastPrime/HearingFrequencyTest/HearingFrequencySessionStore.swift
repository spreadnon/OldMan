//
//  HearingFrequencySessionStore.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import Foundation

@MainActor
final class HearingFrequencySessionStore: ObservableObject {
    @Published private(set) var sessions: [HearingFrequencySessionResult] = []

    private let repository: HearingFrequencySessionRepository
    private let limit: Int

    init(repository: HearingFrequencySessionRepository = HearingFrequencySessionRepository(), limit: Int = 30) {
        self.repository = repository
        self.limit = limit
        reload()
    }

    func reload() {
        sessions = repository.loadSessions()
    }

    func add(_ session: HearingFrequencySessionResult) {
        repository.saveSession(session, limit: limit)
        reload()
    }

    func clear() {
        repository.clear()
        reload()
    }
}

