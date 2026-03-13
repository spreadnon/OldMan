//
//  BalanceShakeGameView.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import SwiftUI

struct BalanceShakeGameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @ObservedObject var store: BalanceShakeSessionStore
    let config: BalanceShakeConfig

    @StateObject private var viewModel: BalanceShakeViewModel
    @State private var hasSavedSession: Bool = false

    init(store: BalanceShakeSessionStore, config: BalanceShakeConfig) {
        self.store = store
        self.config = config
        _viewModel = StateObject(wrappedValue: BalanceShakeViewModel(config: config))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color(red: 57/255, green: 70/255, blue: 83/255)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()

            VStack(spacing: 14) {
                topBar
                Spacer()
                gameArea
                Spacer()
                bottomHint
            }
            .padding(16)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.stop(cancelled: true)
                    dismiss()
                } label: {
                    Label("退出", systemImage: "xmark.circle.fill")
                        .labelStyle(.iconOnly)
                }.tint(.white)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            hasSavedSession = false
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop(cancelled: true)
        }
        .onReceive(viewModel.$phase) { phase in
            guard case .finished(let session) = phase else { return }
            if hasSavedSession { return }
            if session.endReason != .cancelled {
                store.add(session)
            }
            hasSavedSession = true
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active, viewModel.isInProgress {
                viewModel.stop(cancelled: true)
                dismiss()
            }
        }
    }

    private var topBar: some View {
        HStack {
            Text(timerText)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            if viewModel.isUsingSimulation {
                Text("模拟")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.15))
                    .clipShape(Capsule())
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .accessibilityHidden(true)
    }

    private var timerText: String {
        let seconds = Double(viewModel.elapsedMs) / 1000.0
        return String(format: "%.1f s", seconds)
    }

    private var gameArea: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let radius = size * 0.36
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)

            ZStack {
                Circle()
                    .stroke(.white.opacity(0.25), lineWidth: 2)
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)

                Circle()
                    .stroke(.white.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
                    .frame(width: radius * 0.9, height: radius * 0.9)
                    .position(center)

                Circle()
                    .fill(viewModel.isUnstable ? Color.red.opacity(0.9) : Color.white.opacity(0.95))
                    .frame(width: 22, height: 22)
                    .position(
                        x: center.x + CGFloat(viewModel.displayOffset.x) * radius,
                        y: center.y + CGFloat(viewModel.displayOffset.y) * radius
                    )

                overlayText
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(simulationGesture(radius: radius, center: center))
        }
        .frame(height: 360)
    }

    @ViewBuilder
    private var overlayText: some View {
        switch viewModel.phase {
        case .ready:
            VStack(spacing: 8) {
                Text("准备开始")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text("点击开始")
                    .foregroundStyle(.white.opacity(0.85))
            }

        case .calibrating:
            VStack(spacing: 8) {
                Text("校准中…")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text("请保持静止")
                    .foregroundStyle(.white.opacity(0.85))
            }

        case .balancing:
            VStack(spacing: 8) {
                Text("保持稳定")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text("尽量让圆点停在中心")
                    .foregroundStyle(.white.opacity(0.85))
            }

        case .unavailable(let message):
            VStack(spacing: 10) {
                Text("不可用")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.85))
            }

        case .finished(let session):
            BalanceShakeFinishedView(
                session: session,
                config: config,
                onRetest: {
                    hasSavedSession = false
                    viewModel.start()
                },
                onDone: {
                    dismiss()
                }
            )
        }
    }

    private var bottomHint: some View {
        Group {
            switch viewModel.phase {
            case .finished:
                EmptyView()
            case .unavailable:
                Text("提示：该测试需要动作传感器，建议真机运行。")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            default:
                Text("目标：坚持 ≥ \(config.targetTimeSec) 秒可视为“高稳定性”。")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func simulationGesture(radius: CGFloat, center: CGPoint) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard viewModel.isUsingSimulation else { return }
                guard case .balancing = viewModel.phase else { return }
                let dx = (value.location.x - center.x) / radius
                let dy = (value.location.y - center.y) / radius
                viewModel.setSimulatedOffset(x: Double(dx), y: Double(dy))
            }
            .onEnded { _ in
                guard viewModel.isUsingSimulation else { return }
                viewModel.setSimulatedOffset(x: 0, y: 0)
            }
    }
}

private struct BalanceShakeFinishedView: View {
    let session: BalanceShakeSessionResult
    let config: BalanceShakeConfig
    let onRetest: () -> Void
    let onDone: () -> Void

    var body: some View {
        let seconds = Double(session.durationMs) / 1000.0
        let level = BalanceStabilityLevel.from(durationMs: session.durationMs)

        return VStack(spacing: 18) {
            Text("本轮结果")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.95))

            Text(String(format: "稳定 %.1f 秒", seconds))
                .font(.system(size: 44, weight: .black))
                .foregroundStyle(.white)

            Text("\(level.title) \(level.ageReferenceText)")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))

            VStack(alignment: .leading, spacing: 12) {
                Text("年龄参考（仅供娱乐）")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.95))
                ForEach(BalanceShakeAgeReference.lines, id: \.self) { line in
                    Text(line)
                        .foregroundStyle(.white.opacity(0.9))
                }
                Text(BalanceShakeAgeReference.disclaimer)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                Button {
                    onRetest()
                } label: {
                    Text("再测一次")
                        .frame(maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.25))

                Button {
                    onDone()
                } label: {
                    Text("完成")
                        .frame(maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(.bordered)
                .tint(.white)
            }
            .foregroundStyle(.white)
        }
        .padding(.vertical, 10)
    }
}

#Preview {
    NavigationStack {
        BalanceShakeGameView(store: BalanceShakeSessionStore(), config: BalanceShakeConfig(hapticsEnabled: true, soundEnabled: false))
    }
}
