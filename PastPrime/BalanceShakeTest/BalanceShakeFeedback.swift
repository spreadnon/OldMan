//
//  BalanceShakeFeedback.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import AudioToolbox
import UIKit

enum BalanceShakeFeedback {
    static func targetReached(haptics: Bool, sound: Bool) {
        if haptics {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        if sound {
            AudioServicesPlaySystemSound(1025)
        }
    }

    static func finished(haptics: Bool, sound: Bool) {
        if haptics {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        if sound {
            AudioServicesPlaySystemSound(1104)
        }
    }

    static func wobble(haptics: Bool, sound: Bool) {
        if haptics {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        if sound {
            AudioServicesPlaySystemSound(1053)
        }
    }
}

