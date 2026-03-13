//
//  MemorySequenceSessionStore.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import Foundation

@MainActor
final class MemorySequenceSessionStore: ObservableObject {
    @Published private(set) var sessions: [MemorySequenceSessionResult] = []

    private let repository: MemorySequenceSessionRepository
    private let limit: Int

    init(repository: MemorySequenceSessionRepository = MemorySequenceSessionRepository(), limit: Int = 30) {
        self.repository = repository
        self.limit = limit
        reload()
    }

    func reload() {
        sessions = repository.loadSessions()
    }

    func add(_ session: MemorySequenceSessionResult) {
        repository.saveSession(session, limit: limit)
        reload()
    }

    func clear() {
        repository.clear()
        reload()
    }
}

