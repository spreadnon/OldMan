//
//  ReactionTestFeedback.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import AudioToolbox
import UIKit

enum ReactionTestFeedback {
    static func greenAppeared(haptics: Bool, sound: Bool) {
        if haptics {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        if sound {
            AudioServicesPlaySystemSound(1104)
        }
    }

    static func successTap(haptics: Bool, sound: Bool) {
        if haptics {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
        if sound {
            AudioServicesPlaySystemSound(1103)
        }
    }

    static func falseStart(haptics: Bool, sound: Bool) {
        if haptics {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        if sound {
            AudioServicesPlaySystemSound(1053)
        }
    }
}

