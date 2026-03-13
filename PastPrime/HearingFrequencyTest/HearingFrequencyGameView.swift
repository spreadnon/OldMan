//
//  HearingFrequencyGameView.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import SwiftUI

struct HearingFrequencyGameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @ObservedObject var store: HearingFrequencySessionStore
    let config: HearingFrequencyConfig

    @StateObject private var viewModel: HearingFrequencyViewModel
    @State private var hasSavedSession: Bool = false

    init(store: HearingFrequencySessionStore, config: HearingFrequencyConfig) {
        self.store = store
        self.config = config
        _viewModel = StateObject(wrappedValue: HearingFrequencyViewModel(config: config))
    }

    var body: some View {
        ZStack {
//            Color.black.ignoresSafeArea()
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color(red: 70/255, green: 68/255, blue: 38/255)]),
                startPoint: .bottomTrailing,
                endPoint: .topLeading
            ).ignoresSafeArea()


            VStack(spacing: 16) {
                topBar
                Spacer()
                mainContent
                Spacer()
                bottomHint
            }
            .padding(16)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if case .playing = viewModel.phase {
                viewModel.stopByUser()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.cancel()
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
            viewModel.refreshAudioRoute()
        }
        .onDisappear {
            if viewModel.isInProgress {
                viewModel.cancel()
            }
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
                viewModel.cancel()
                dismiss()
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Text(routeBadgeText)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(viewModel.isHeadphonesConnected ? .green.opacity(0.45) : .white.opacity(0.15))
                .clipShape(Capsule())
                .foregroundStyle(.white.opacity(0.9))

            Spacer()

            if case .playing = viewModel.phase {
                Text(String(format: "%.1f s", Double(viewModel.elapsedMs) / 1000.0))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .accessibilityHidden(true)
    }

    private var routeBadgeText: String {
        viewModel.isHeadphonesConnected ? "耳机已连接" : "未检测到耳机"
    }

    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.phase {
        case .ready:
            VStack(spacing: 14) {
                Text("听力频率测试")
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(.white)

                VStack(spacing: 8) {
                    Text("建议佩戴耳机，音量从低开始。")
                    Text("点击开始后，将从高频逐渐降低。听到声音时点击停止。")
                }
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)

                Button {
                    viewModel.start()
                } label: {
                    Text("开始播放")
                        .frame(maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.2))
                .foregroundStyle(.white)
                .padding(.top, 8)
                
            }

        case .playing:
            VStack(spacing: 14) {
                if config.showCurrentFrequency {
                    Text("当前 \(formatHz(viewModel.currentHz))")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.95))
                } else {
                    ProgressView(value: progress)
                        .tint(.white)
                        .frame(maxWidth: 240)
                }

                Text("听到声音就点停止")
                    .font(.system(size: 40, weight: .black))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Button {
                    viewModel.stopByUser()
                } label: {
                    Text("停止")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red.opacity(0.85))
                .foregroundStyle(.white)
                .padding(.top, 8)

                Text("（也可以直接点击屏幕任意位置停止）")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.75))
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("正在播放。听到声音就点击停止。")

        case .unavailable(let message):
            VStack(spacing: 12) {
                Text("不可用")
                    .font(.system(size: 34, weight: .black))
                    .foregroundStyle(.white)
                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.85))
                Button("返回") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .tint(.white)
            }

        case .finished(let session):
            HearingFrequencyFinishedView(
                session: session,
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
            case .playing:
                Text("安全提示：请勿将音量调得过大。若不适请立即停止。")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.78))
                    .multilineTextAlignment(.center)
            case .ready:
                Text("测试频段：\(Int(config.startHz)) Hz → \(Int(config.endHz)) Hz（约 \(Int(config.durationSec)) 秒）")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.78))
                    .multilineTextAlignment(.center)
            default:
                EmptyView()
            }
        }
    }

    private var progress: Double {
        min(1, max(0, Double(viewModel.elapsedMs) / (config.durationSec * 1000.0)))
    }

    private func formatHz(_ hz: Double) -> String {
        String(format: "%.1f kHz", hz / 1000.0)
    }
}

private struct HearingFrequencyFinishedView: View {
    let session: HearingFrequencySessionResult
    let onRetest: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Text("本轮结果")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.95))

            if let hz = session.detectedHz {
                let level = HearingFrequencyLevel.from(detectedHz: hz)
                Text("最高可听 \(formatHz(hz))")
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(.white)
                Text("\(level.ageReferenceText)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
            } else {
                Text("未检测到")
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(.white)
                Text("（可能音量过低 / 未佩戴耳机 / 未点击停止）")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.8))
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("年龄参考（仅供娱乐）")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.95))
                ForEach(HearingFrequencyAgeReference.lines, id: \.self) { line in
                    Text(line)
                        .foregroundStyle(.white.opacity(0.9))
                }
                Text(HearingFrequencyAgeReference.disclaimer)
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

    private func formatHz(_ hz: Int) -> String {
        String(format: "%.1f kHz", Double(hz) / 1000.0)
    }
}

#Preview {
    NavigationStack {
        HearingFrequencyGameView(
            store: HearingFrequencySessionStore(),
            config: HearingFrequencyConfig(hapticsEnabled: true, showCurrentFrequency: false)
        )
    }
}
