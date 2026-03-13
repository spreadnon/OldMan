//
//  HearingFrequencyAudioController.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import AVFoundation

final class HearingFrequencyAudioController {
    struct Config: Hashable {
        let startHz: Double
        let endHz: Double
        let durationSec: Double
        let amplitude: Double
    }

    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var playbackBuffer: AVAudioPCMBuffer?

    func start(config: Config) throws -> Double {
        stop()

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetoothA2DP])
        } catch {
            try session.setCategory(.playback, mode: .default)
        }
        try session.setActive(true)

        let latencyCompensationSec = session.outputLatency + session.ioBufferDuration

        let engine = AVAudioEngine()
        let outputFormat = engine.outputNode.outputFormat(forBus: 0)
        let sampleRate = outputFormat.sampleRate
        let channelCount = max(1, outputFormat.channelCount)

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: channelCount)!

        let playerNode = AVAudioPlayerNode()
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 1.0

        let buffer = makeSweepBuffer(format: format, config: config)
        playerNode.scheduleBuffer(buffer, at: nil, options: [])

        engine.prepare()
        try engine.start()
        playerNode.play()

        self.engine = engine
        self.playerNode = playerNode
        self.playbackBuffer = buffer

        return latencyCompensationSec
    }

    func stop() {
        if let playerNode, let engine {
            playerNode.stop()
            engine.disconnectNodeInput(playerNode)
            engine.disconnectNodeOutput(playerNode)
            engine.detach(playerNode)
        }

        engine?.stop()
        engine = nil
        playerNode = nil
        playbackBuffer = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    private func makeSweepBuffer(format: AVAudioFormat, config: Config) -> AVAudioPCMBuffer {
        let sampleRate = format.sampleRate
        let channelCount = Int(format.channelCount)

        let nyquistHz = sampleRate / 2.0
        let startHz = min(max(1, config.startHz), nyquistHz * 0.9)
        let endHz = max(1, min(config.endHz, startHz))
        let durationSec = max(1, config.durationSec)

        let durationSamples = max(1, Int(durationSec * sampleRate))
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(durationSamples))!
        buffer.frameLength = buffer.frameCapacity

        guard let channelData = buffer.floatChannelData else {
            return buffer
        }

        let ratioPerSample = pow(endHz / startHz, 1.0 / Double(durationSamples))
        let amplitude = Double(Float(min(max(config.amplitude, 0), 1)))
        let twoPi = 2.0 * Double.pi

        var phase = 0.0
        var currentHz = startHz

        let attackSamples = max(1, Int(sampleRate * 0.02))

        for i in 0..<durationSamples {
            let attack = min(1.0, Double(i) / Double(attackSamples))
            let sample = Float(sin(phase) * amplitude * attack)

            for c in 0..<channelCount {
                channelData[c][i] = sample
            }

            phase += twoPi * currentHz / sampleRate
            if phase > twoPi {
                phase -= twoPi
            }

            currentHz = max(endHz, currentHz * ratioPerSample)
        }

        return buffer
    }
}
