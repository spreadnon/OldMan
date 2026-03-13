//
//  ReactionTestSessionRepository.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import Foundation

final class ReactionTestSessionRepository {
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

    func loadSessions() -> [SessionResult] {
        guard let data = userDefaults.data(forKey: ReactionTestDefaultsKeys.sessionsKey) else {
            return []
        }
        do {
            return try decoder.decode([SessionResult].self, from: data)
        } catch {
            return []
        }
    }

    func saveSession(_ session: SessionResult, limit: Int) {
        var sessions = loadSessions()
        sessions.insert(session, at: 0)
        if sessions.count > limit {
            sessions = Array(sessions.prefix(limit))
        }
        do {
            let data = try encoder.encode(sessions)
            userDefaults.set(data, forKey: ReactionTestDefaultsKeys.sessionsKey)
        } catch {
            // Ignore persistence failures in v1.
        }
    }

    func clear() {
        userDefaults.removeObject(forKey: ReactionTestDefaultsKeys.sessionsKey)
    }
}

