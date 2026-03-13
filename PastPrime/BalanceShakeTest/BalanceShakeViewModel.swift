//
//  BalanceShakeViewModel.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import CoreMotion
import Foundation

enum BalanceShakePhase: Equatable {
    case ready
    case calibrating
    case balancing
    case unavailable(message: String)
    case finished(session: BalanceShakeSessionResult)
}

@MainActor
final class BalanceShakeViewModel: ObservableObject {
    @Published private(set) var phase: BalanceShakePhase = .ready
    @Published private(set) var elapsedMs: Int = 0
    @Published private(set) var displayOffset: BalanceNormalizedOffset = .zero
    @Published private(set) var rawMagnitude: Double = 0
    @Published private(set) var isUnstable: Bool = false

    let config: BalanceShakeConfig

    var isUsingSimulation: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    private let motionManager = CMMotionManager()
    private let motionQueue: OperationQueue = {
        let q = OperationQueue()
        q.name = "balanceShake.motion.queue"
        q.qualityOfService = .userInteractive
        return q
    }()

    private var calibrationSamples: [(roll: Double, pitch: Double)] = []
    private let calibrationSampleCount: Int = 20
    private var baselineRoll: Double = 0
    private var baselinePitch: Double = 0

    private var startUptimeNs: UInt64?
    private var unstableFrames: Int = 0
    private var maxDeviationRad: Double = 0
    private var hasReachedTarget: Bool = false

    private var simulatedOffset: BalanceNormalizedOffset = .zero
    private var tickTask: Task<Void, Never>?

    init(config: BalanceShakeConfig) {
        self.config = config
    }

    var isInProgress: Bool {
        switch phase {
        case .calibrating, .balancing:
            return true
        case .ready, .unavailable, .finished:
            return false
        }
    }

    func start() {
        stop(cancelled: false)

        elapsedMs = 0
        displayOffset = .zero
        rawMagnitude = 0
        isUnstable = false

        calibrationSamples = []
        baselineRoll = 0
        baselinePitch = 0

        startUptimeNs = nil
        unstableFrames = 0
        maxDeviationRad = 0
        hasReachedTarget = false

        simulatedOffset = .zero

        if isUsingSimulation {
            startUptimeNs = DispatchTime.now().uptimeNanoseconds
            phase = .balancing
            startSimulationTick()
            return
        }

        guard motionManager.isDeviceMotionAvailable else {
            phase = .unavailable(message: "设备不支持动作传感器（需要真机）。")
            return
        }

        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        phase = .calibrating

        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: motionQueue) { [weak self] motion, _ in
            guard let self, let motion else { return }
            DispatchQueue.main.async {
                self.handleDeviceMotion(motion)
            }
        }
    }

    func stop(cancelled: Bool) {
        tickTask?.cancel()
        tickTask = nil

        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }

        if cancelled, isInProgress, let session = makeSession(endReason: .cancelled) {
            phase = .finished(session: session)
            return
        }

        if case .unavailable = phase {
            return
        }
        if case .finished = phase {
            return
        }

        phase = .ready
    }

    func setSimulatedOffset(x: Double, y: Double) {
        let raw = BalanceNormalizedOffset(x: x, y: y).clamped(maxAbs: 2)
        simulatedOffset = raw
        updateWithRawNormalizedOffset(raw, deviationRad: raw.magnitude * config.wobbleThresholdRad)
    }

    private func startSimulationTick() {
        tickTask?.cancel()
        tickTask = Task.detached { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 16_666_667)
                await self.tickSimulation()
            }
        }
    }

    private func tickSimulation() {
        guard case .balancing = phase else { return }
        let deviationRad = simulatedOffset.magnitude * config.wobbleThresholdRad
        updateWithRawNormalizedOffset(simulatedOffset, deviationRad: deviationRad)
    }

    private func handleDeviceMotion(_ motion: CMDeviceMotion) {
        switch phase {
        case .calibrating:
            let roll = motion.attitude.roll
            let pitch = motion.attitude.pitch
            calibrationSamples.append((roll: roll, pitch: pitch))

            if calibrationSamples.count >= calibrationSampleCount {
                let avgRoll = calibrationSamples.map(\.roll).reduce(0, +) / Double(calibrationSamples.count)
                let avgPitch = calibrationSamples.map(\.pitch).reduce(0, +) / Double(calibrationSamples.count)
                baselineRoll = avgRoll
                baselinePitch = avgPitch

                startUptimeNs = DispatchTime.now().uptimeNanoseconds
                phase = .balancing
            }

        case .balancing:
            let deltaRoll = motion.attitude.roll - baselineRoll
            let deltaPitch = motion.attitude.pitch - baselinePitch

            let deviationRad = (deltaRoll * deltaRoll + deltaPitch * deltaPitch).squareRoot()
            maxDeviationRad = max(maxDeviationRad, deviationRad)

            let rawX = deltaRoll / config.wobbleThresholdRad
            let rawY = -deltaPitch / config.wobbleThresholdRad
            updateWithRawNormalizedOffset(BalanceNormalizedOffset(x: rawX, y: rawY), deviationRad: deviationRad)

        case .ready, .unavailable, .finished:
            break
        }
    }

    private func updateWithRawNormalizedOffset(_ rawOffset: BalanceNormalizedOffset, deviationRad: Double) {
        guard case .balancing = phase else { return }

        maxDeviationRad = max(maxDeviationRad, deviationRad)

        let nowNs = DispatchTime.now().uptimeNanoseconds
        if let startUptimeNs {
            elapsedMs = max(0, Int((nowNs - startUptimeNs) / 1_000_000))
        }

        rawMagnitude = rawOffset.magnitude
        isUnstable = rawMagnitude > 1.0
        displayOffset = rawOffset.clampedToUnitCircle()

        if isUnstable {
            unstableFrames += 1
        } else {
            unstableFrames = max(0, unstableFrames - 1)
        }

        if !hasReachedTarget, elapsedMs >= config.targetTimeSec * 1000 {
            hasReachedTarget = true
            BalanceShakeFeedback.targetReached(haptics: config.hapticsEnabled, sound: config.soundEnabled)
        }

        if elapsedMs >= config.maxTimeSec * 1000 {
            finish(endReason: .reachedMaxTime)
            return
        }

        if unstableFrames >= config.wobbleGraceFrames {
            finish(endReason: .wobble)
        }
    }

    private func finish(endReason: BalanceShakeEndReason) {
        guard let session = makeSession(endReason: endReason) else { return }

        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
        tickTask?.cancel()
        tickTask = nil

        phase = .finished(session: session)

        switch endReason {
        case .wobble:
            BalanceShakeFeedback.wobble(haptics: config.hapticsEnabled, sound: config.soundEnabled)
        case .reachedMaxTime:
            BalanceShakeFeedback.finished(haptics: config.hapticsEnabled, sound: config.soundEnabled)
        case .cancelled:
            break
        }
    }

    private func makeSession(endReason: BalanceShakeEndReason) -> BalanceShakeSessionResult? {
        guard let startUptimeNs else { return nil }
        let nowNs = DispatchTime.now().uptimeNanoseconds
        let durationMs = max(0, Int((nowNs - startUptimeNs) / 1_000_000))

        return BalanceShakeSessionResult(
            durationMs: durationMs,
            maxDeviationRad: maxDeviationRad,
            endReason: endReason,
            createdAt: Date()
        )
    }
}
