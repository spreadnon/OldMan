//
//  MemorySequenceFeedback.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import UIKit

enum MemorySequenceFeedback {
    static func flash(haptics: Bool) {
        guard haptics else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success(haptics: Bool) {
        guard haptics else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func failure(haptics: Bool) {
        guard haptics else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

