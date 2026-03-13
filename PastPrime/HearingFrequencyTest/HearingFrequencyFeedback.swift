//
//  HearingFrequencyFeedback.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import UIKit

enum HearingFrequencyFeedback {
    static func started(haptics: Bool) {
        guard haptics else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func finished(haptics: Bool) {
        guard haptics else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func cancelled(haptics: Bool) {
        guard haptics else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

