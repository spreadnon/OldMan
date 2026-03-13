//
//  MemorySequenceSessionRepository.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import Foundation

final class MemorySequenceSessionRepository {
    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func loadSessions() -> [MemorySequenceSessionResult] {
        guard let data = userDefaults.data(forKey: MemorySequenceDefaultsKeys.sessionsKey) else {
            return []
        }
        do {
            return try decoder.decode([MemorySequenceSessionResult].self, from: data)
        } catch {
            return []
        }
    }

    func saveSession(_ session: MemorySequenceSessionResult, limit: Int) {
        var sessions = loadSessions()
        sessions.insert(session, at: 0)
        if sessions.count > limit {
            sessions = Array(sessions.prefix(limit))
        }
        do {
            let data = try encoder.encode(sessions)
            userDefaults.set(data, forKey: MemorySequenceDefaultsKeys.sessionsKey)
        } catch {
            // Ignore persistence failures in v1.
        }
    }

    func clear() {
        userDefaults.removeObject(forKey: MemorySequenceDefaultsKeys.sessionsKey)
    }
}

