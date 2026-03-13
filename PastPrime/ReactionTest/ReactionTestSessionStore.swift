//
//  ReactionTestSessionStore.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import Foundation

@MainActor
final class ReactionTestSessionStore: ObservableObject {
    @Published private(set) var sessions: [SessionResult] = []

    private let repository: ReactionTestSessionRepository
    private let limit: Int

    init(repository: ReactionTestSessionRepository = ReactionTestSessionRepository(), limit: Int = 30) {
        self.repository = repository
        self.limit = limit
        reload()
    }

    func reload() {
        sessions = repository.loadSessions()
    }

    func add(_ session: SessionResult) {
        repository.saveSession(session, limit: limit)
        reload()
    }

    func clear() {
        repository.clear()
        reload()
    }
}

