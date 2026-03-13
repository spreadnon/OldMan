//
//  HearingFrequencyViewModel.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import AVFoundation
import Foundation

enum HearingFrequencyPhase: Equatable {
    case ready
    case playing
    case unavailable(message: String)
    case finished(session: HearingFrequencySessionResult)
}

@MainActor
final class HearingFrequencyViewModel: ObservableObject {
    @Published private(set) var phase: HearingFrequencyPhase = .ready
    @Published private(set) var elapsedMs: Int = 0
    @Published private(set) var currentHz: Double = 0
    @Published private(set) var isHeadphonesConnected: Bool = false
    @Published private(set) var outputRouteText: String = ""

    let config: HearingFrequencyConfig

    private let audioController = HearingFrequencyAudioController()
    private var startedAtUptimeNs: UInt64?
    private var tickTask: Task<Void, Never>?
    private var latencyCompensationSec: Double = 0

    init(config: HearingFrequencyConfig) {
        self.config = config
        refreshAudioRoute()
        currentHz = config.startHz
    }

    var isInProgress: Bool {
        if case .playing = phase { return true }
        return false
    }

    func refreshAudioRoute() {
        let session = AVAudioSession.sharedInstance()
        let outputs = session.currentRoute.outputs
        outputRouteText = outputs.map { $0.portType.rawValue }.joined(separator: ", ")
        isHeadphonesConnected = outputs.contains(where: { isHeadphonesPort($0.portType) })
    }

    func start() {
        stopInternal()

        refreshAudioRoute()
        elapsedMs = 0
        currentHz = config.startHz

        do {
            latencyCompensationSec = try audioController.start(
                config: .init(
                    startHz: config.startHz,
                    endHz: config.endHz,
                    durationSec: config.durationSec,
                    amplitude: config.amplitude
                )
            )
        } catch {
            let nsError = error as NSError
            let details = "\(nsError.domain) (\(nsError.code))"
            phase = .unavailable(message: "音频启动失败：\(details)\n\(nsError.localizedDescription)")
            return
        }

        startedAtUptimeNs = DispatchTime.now().uptimeNanoseconds
        phase = .playing
        HearingFrequencyFeedback.started(haptics: config.hapticsEnabled)
        startTick()
    }

    func stopByUser() {
        finish(endReason: .stoppedByUser)
    }

    func cancel() {
        finish(endReason: .cancelled)
    }

    private func startTick() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 33_333_333)
                self.tick()
            }
        }
    }

    private func tick() {
        guard case .playing = phase else { return }
        guard let startedAtUptimeNs else { return }

        let nowNs = DispatchTime.now().uptimeNanoseconds
        let elapsedSec = Double(nowNs - startedAtUptimeNs) / 1_000_000_000.0
        elapsedMs = max(0, Int(elapsedSec * 1000))

        let effectiveElapsedSec = max(0, elapsedSec - latencyCompensationSec)
        currentHz = sweepFrequency(elapsedSec: effectiveElapsedSec)

        if elapsedSec >= config.durationSec {
            finish(endReason: .timeout)
        }
    }

    private func finish(endReason: HearingFrequencyEndReason) {
        tickTask?.cancel()
        tickTask = nil

        let nowNs = DispatchTime.now().uptimeNanoseconds
        let durationMs = durationMs(nowNs: nowNs)

        let detectedHz: Int? = {
            guard endReason == .stoppedByUser else { return nil }
            let effectiveElapsedSec = max(0, Double(durationMs) / 1000.0 - latencyCompensationSec)
            return Int(sweepFrequency(elapsedSec: effectiveElapsedSec).rounded())
        }()

        let session = HearingFrequencySessionResult(
            detectedHz: detectedHz,
            durationMs: durationMs,
            startHz: Int(config.startHz.rounded()),
            endHz: Int(config.endHz.rounded()),
            outputRoute: outputRouteText.isEmpty ? "unknown" : outputRouteText,
            endReason: endReason,
            createdAt: Date()
        )

        audioController.stop()

        switch endReason {
        case .stoppedByUser, .timeout:
            HearingFrequencyFeedback.finished(haptics: config.hapticsEnabled)
        case .cancelled:
            HearingFrequencyFeedback.cancelled(haptics: config.hapticsEnabled)
        }

        startedAtUptimeNs = nil
        phase = .finished(session: session)
    }

    private func stopInternal() {
        tickTask?.cancel()
        tickTask = nil
        audioController.stop()
        startedAtUptimeNs = nil
        phase = .ready
    }

    private func durationMs(nowNs: UInt64) -> Int {
        guard let startedAtUptimeNs else { return 0 }
        return max(0, Int((nowNs - startedAtUptimeNs) / 1_000_000))
    }

    private func sweepFrequency(elapsedSec: Double) -> Double {
        let startHz = max(1, config.startHz)
        let endHz = max(1, min(config.endHz, startHz))
        let durationSec = max(1, config.durationSec)

        let t = min(max(elapsedSec, 0), durationSec)
        let ratio = endHz / startHz
        return startHz * pow(ratio, t / durationSec)
    }

    private func isHeadphonesPort(_ portType: AVAudioSession.Port) -> Bool {
        switch portType {
        case .headphones, .bluetoothA2DP, .bluetoothHFP, .bluetoothLE, .airPlay, .carAudio, .usbAudio:
            return true
        default:
            return false
        }
    }
}
