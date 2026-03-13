//
//  ReactionTestViewModel.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import Foundation

enum ReactionTestPhase {
    case ready
    case waiting(trialIndex: Int)
    case green(trialIndex: Int)
    case falseStart(trialIndex: Int)
    case trialResult(trialIndex: Int, reactionMs: Int)
    case finished(session: SessionResult)
}

@MainActor
final class ReactionTestViewModel: ObservableObject {
    @Published private(set) var phase: ReactionTestPhase = .ready
    @Published private(set) var successfulTrials: [TrialResult] = []
    @Published private(set) var falseStartCount: Int = 0

    let config: ReactionTestConfig

    private var waitTask: Task<Void, Never>?
    private var greenAtUptimeNs: UInt64?
    private var waitDelayMs: Int?
    private var ignoreTapsUntilUptimeNs: UInt64 = 0

    init(config: ReactionTestConfig) {
        self.config = config
    }

    var isInProgress: Bool {
        switch phase {
        case .waiting, .green, .falseStart, .trialResult:
            return true
        case .ready, .finished:
            return false
        }
    }

    func startNewSession() {
        waitTask?.cancel()
        successfulTrials = []
        falseStartCount = 0
        greenAtUptimeNs = nil
        waitDelayMs = nil
        ignoreTapsUntilUptimeNs = 0
        startWaiting(trialIndex: 1)
    }

    func cancelSession() {
        waitTask?.cancel()
        waitTask = nil
        phase = .ready
    }

    func handleTap() {
        let nowNs = DispatchTime.now().uptimeNanoseconds
        if nowNs < ignoreTapsUntilUptimeNs {
            return
        }

        switch phase {
        case .ready:
            startNewSession()

        case .waiting(let trialIndex):
            waitTask?.cancel()
            waitTask = nil

            falseStartCount += 1
            phase = .falseStart(trialIndex: trialIndex)
            ReactionTestFeedback.falseStart(haptics: config.hapticsEnabled, sound: config.soundEnabled)
            ignoreTapsUntilUptimeNs = nowNs + UInt64(config.tapCooldownMs) * 1_000_000

        case .falseStart(let trialIndex):
            startWaiting(trialIndex: trialIndex)

        case .green(let trialIndex):
            guard let greenAtUptimeNs else {
                return
            }

            let reactionMs = max(0, Int((nowNs - greenAtUptimeNs) / 1_000_000))
            let trial = TrialResult(
                index: trialIndex,
                outcome: .success,
                reactionMs: reactionMs,
                waitDelayMs: waitDelayMs,
                timestamp: Date()
            )
            successfulTrials.append(trial)
            ReactionTestFeedback.successTap(haptics: config.hapticsEnabled, sound: config.soundEnabled)

            if trialIndex >= config.trialCount {
                finishSession()
            } else {
                phase = .trialResult(trialIndex: trialIndex, reactionMs: reactionMs)
                ignoreTapsUntilUptimeNs = nowNs + UInt64(config.tapCooldownMs) * 1_000_000
            }

        case .trialResult(let trialIndex, _):
            startWaiting(trialIndex: trialIndex + 1)

        case .finished:
            break
        }
    }

    private func startWaiting(trialIndex: Int) {
        waitTask?.cancel()
        waitTask = nil

        greenAtUptimeNs = nil

        let delayMs = Int.random(in: config.delayRangeMs)
        waitDelayMs = delayMs

        phase = .waiting(trialIndex: trialIndex)

        waitTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(nanoseconds: UInt64(delayMs) * 1_000_000)
            } catch {
                return
            }
            if Task.isCancelled {
                return
            }
            self.enterGreen(trialIndex: trialIndex)
        }
    }

    private func enterGreen(trialIndex: Int) {
        greenAtUptimeNs = DispatchTime.now().uptimeNanoseconds
        phase = .green(trialIndex: trialIndex)
        ReactionTestFeedback.greenAppeared(haptics: config.hapticsEnabled, sound: config.soundEnabled)
    }

    private func finishSession() {
        waitTask?.cancel()
        waitTask = nil

        let reactionMs = successfulTrials.compactMap(\.reactionMs)
        let averageMs: Int? = {
            guard !reactionMs.isEmpty else { return nil }
            let sum = reactionMs.reduce(0, +)
            return Int((Double(sum) / Double(reactionMs.count)).rounded())
        }()

        let bestMs = reactionMs.min()

        let session = SessionResult(
            trialCount: config.trialCount,
            trials: successfulTrials,
            averageMs: averageMs,
            bestMs: bestMs,
            falseStartCount: falseStartCount,
            createdAt: Date()
        )
        phase = .finished(session: session)
    }
}
