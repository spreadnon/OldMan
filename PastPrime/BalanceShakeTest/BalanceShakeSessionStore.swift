//
//  BalanceShakeSessionStore.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import Foundation

@MainActor
final class BalanceShakeSessionStore: ObservableObject {
    @Published private(set) var sessions: [BalanceShakeSessionResult] = []

    private let repository: BalanceShakeSessionRepository
    private let limit: Int

    init(repository: BalanceShakeSessionRepository = BalanceShakeSessionRepository(), limit: Int = 30) {
        self.repository = repository
        self.limit = limit
        reload()
    }

    func reload() {
        sessions = repository.loadSessions()
    }

    func add(_ session: BalanceShakeSessionResult) {
        repository.saveSession(session, limit: limit)
        reload()
    }

    func clear() {
        repository.clear()
        reload()
    }
}

