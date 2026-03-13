//
//  MemorySequenceViewModel.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import Foundation

enum MemorySequencePhase: Equatable {
    case ready
    case showing(items: Int)
    case input(items: Int, progress: Int)
    case finished(session: MemorySequenceSessionResult)
}

@MainActor
final class MemorySequenceViewModel: ObservableObject {
    @Published private(set) var phase: MemorySequencePhase = .ready
    @Published private(set) var highlightedIndex: Int?
    @Published private(set) var tapFlashIndex: Int?
    @Published private(set) var bestItems: Int = 0

    let config: MemorySequenceConfig

    private var sequence: [Int] = []
    private var inputIndex: Int = 0
    private var showTask: Task<Void, Never>?
    private var tapFlashTask: Task<Void, Never>?

    init(config: MemorySequenceConfig) {
        self.config = config
    }

    var isInProgress: Bool {
        switch phase {
        case .showing, .input:
            return true
        case .ready, .finished:
            return false
        }
    }

    func start() {
        reset()
        beginLevel(startItems: config.startItems)
    }

    func cancel() {
        finish(endReason: .cancelled)
    }

    func reset() {
        showTask?.cancel()
        tapFlashTask?.cancel()
        showTask = nil
        tapFlashTask = nil

        highlightedIndex = nil
        tapFlashIndex = nil
        bestItems = 0

        sequence = []
        inputIndex = 0
        phase = .ready
    }

    func handleTap(index: Int) {
        guard case .input(let items, _) = phase else { return }
        flashTap(index: index)

        guard inputIndex < sequence.count else { return }

        if index != sequence[inputIndex] {
            MemorySequenceFeedback.failure(haptics: config.hapticsEnabled)
            finish(endReason: .failed, reachedItems: items)
            return
        }

        inputIndex += 1
        let newProgress = inputIndex
        phase = .input(items: items, progress: newProgress)

        if inputIndex >= sequence.count {
            MemorySequenceFeedback.success(haptics: config.hapticsEnabled)
            bestItems = max(bestItems, sequence.count)
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 350_000_000)
                guard let self else { return }
                await self.advanceLevel()
            }
        }
    }

    private func flashTap(index: Int) {
        tapFlashTask?.cancel()
        tapFlashIndex = index
        tapFlashTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 120_000_000)
            await MainActor.run {
                if self?.tapFlashIndex == index {
                    self?.tapFlashIndex = nil
                }
            }
        }
    }

    private func beginLevel(startItems: Int) {
        let gridCount = config.gridSide * config.gridSide
        let clampedStart = max(1, min(startItems, 18))

        sequence = makeRandomSequence(count: clampedStart, gridCount: gridCount)
        inputIndex = 0
        phase = .showing(items: sequence.count)
        playSequence()
    }

    private func advanceLevel() async {
        guard case .input = phase else { return }
        let gridCount = config.gridSide * config.gridSide
        let next = nextIndex(gridCount: gridCount, avoid: sequence.last)
        sequence.append(next)
        inputIndex = 0
        phase = .showing(items: sequence.count)
        playSequence()
    }

    private func playSequence() {
        showTask?.cancel()
        showTask = Task { [weak self] in
            guard let self else { return }

            let flashNs = UInt64(max(120, config.flashMs)) * 1_000_000
            let gapNs = UInt64(max(80, config.gapMs)) * 1_000_000

            for index in sequence {
                if Task.isCancelled { return }
                await MainActor.run {
                    self.highlightedIndex = index
                    MemorySequenceFeedback.flash(haptics: self.config.hapticsEnabled)
                }
                try? await Task.sleep(nanoseconds: flashNs)
                if Task.isCancelled { return }
                await MainActor.run {
                    self.highlightedIndex = nil
                }
                try? await Task.sleep(nanoseconds: gapNs)
            }

            if Task.isCancelled { return }
            await MainActor.run {
                self.phase = .input(items: self.sequence.count, progress: 0)
            }
        }
    }

    private func finish(endReason: MemorySequenceEndReason, reachedItems: Int? = nil) {
        showTask?.cancel()
        tapFlashTask?.cancel()
        showTask = nil
        tapFlashTask = nil

        highlightedIndex = nil
        tapFlashIndex = nil

        let reached = reachedItems ?? sequence.count
        let session = MemorySequenceSessionResult(
            bestItems: bestItems,
            startItems: config.startItems,
            reachedItems: reached,
            endReason: endReason
        )
        phase = .finished(session: session)
    }

    private func makeRandomSequence(count: Int, gridCount: Int) -> [Int] {
        var result: [Int] = []
        result.reserveCapacity(count)
        var last: Int?
        for _ in 0..<count {
            let next = nextIndex(gridCount: gridCount, avoid: last)
            result.append(next)
            last = next
        }
        return result
    }

    private func nextIndex(gridCount: Int, avoid: Int?) -> Int {
        var candidate = Int.random(in: 0..<gridCount)
        if let avoid, gridCount > 1 {
            while candidate == avoid {
                candidate = Int.random(in: 0..<gridCount)
            }
        }
        return candidate
    }
}

