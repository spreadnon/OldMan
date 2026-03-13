//
//  PastPrimeScore.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import Foundation
import SwiftUI

enum PastPrimeRank: String, CaseIterable {
    case xiao = "小登"
    case zhong = "中登"
    case lao = "老登"

    static func from(score: Double) -> PastPrimeRank {
        if score >= 80 { return .xiao }
        if score >= 50 { return .zhong }
        return .lao
    }

    var tint: Color {
        switch self {
        case .xiao:
            return .green
        case .zhong:
            return .orange
        case .lao:
            return .red
        }
    }
}

enum PastPrimeScore {
    static func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.max(min, Swift.min(value, max))
    }

    static func lerp(_ x: Double, _ x0: Double, _ x1: Double, _ y0: Double, _ y1: Double) -> Double {
        guard x1 != x0 else { return y0 }
        let t = (x - x0) / (x1 - x0)
        return y0 + t * (y1 - y0)
    }

    static func piecewiseScore(x: Double, points: [(Double, Double)]) -> Double {
        precondition(points.count >= 2)
        let sorted = points.sorted(by: { $0.0 < $1.0 })

        if x <= sorted.first!.0 { return sorted.first!.1 }
        if x >= sorted.last!.0 { return sorted.last!.1 }

        for i in 0..<(sorted.count - 1) {
            let (x0, y0) = sorted[i]
            let (x1, y1) = sorted[i + 1]
            if x >= x0, x <= x1 {
                return lerp(x, x0, x1, y0, y1)
            }
        }
        return sorted.last!.1
    }

    // Lower is better.
    static func reaction(averageMs: Int) -> Double {
        let x = Double(averageMs)
        let score = piecewiseScore(
            x: x,
            points: [
                (180, 100),
                (220, 80),
                (280, 50),
                (350, 20),
                (450, 0),
            ]
        )
        return clamp(score, min: 0, max: 100)
    }

    // Higher is better.
    static func balance(durationMs: Int) -> Double {
        let x = Double(durationMs) / 1000.0
        let score = piecewiseScore(
            x: x,
            points: [
                (0, 0),
                (5, 20),
                (10, 50),
                (20, 80),
                (30, 100),
            ]
        )
        return clamp(score, min: 0, max: 100)
    }

    // Higher is better.
    static func hearing(detectedHz: Int) -> Double {
        let x = Double(detectedHz) / 1000.0
        let score = piecewiseScore(
            x: x,
            points: [
                (4, 0),
                (8, 20),
                (10, 50),
                (15, 80),
                (18, 100),
            ]
        )
        return clamp(score, min: 0, max: 100)
    }

    // Higher is better.
    static func memory(bestItems: Int) -> Double {
        let x = Double(bestItems)
        let score = piecewiseScore(
            x: x,
            points: [
                (3, 0),
                (5, 20),
                (6, 50),
                (8, 80),
                (10, 100),
            ]
        )
        return clamp(score, min: 0, max: 100)
    }

    static func overall(scores: [Double]) -> Double? {
        let valid = scores.filter { $0.isFinite }
        guard !valid.isEmpty else { return nil }
        return valid.reduce(0, +) / Double(valid.count)
    }
}
