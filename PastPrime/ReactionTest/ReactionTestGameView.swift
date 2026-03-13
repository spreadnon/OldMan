//
//  ReactionTestGameView.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import SwiftUI

struct ReactionTestGameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @ObservedObject var store: ReactionTestSessionStore
    let config: ReactionTestConfig

    @StateObject private var viewModel: ReactionTestViewModel
    @State private var hasSavedSession: Bool = false

    init(store: ReactionTestSessionStore, config: ReactionTestConfig) {
        self.store = store
        self.config = config
        _viewModel = StateObject(wrappedValue: ReactionTestViewModel(config: config))
    }

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

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
            viewModel.handleTap()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.cancelSession()
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
            viewModel.startNewSession()
        }
        .onReceive(viewModel.$phase) { phase in
            guard case .finished(let session) = phase else { return }
            if hasSavedSession { return }
            store.add(session)
            hasSavedSession = true
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active, viewModel.isInProgress {
                viewModel.cancelSession()
                dismiss()
            }
        }
    }

    private var waitingColor: Color {
        config.colorBlindModeEnabled ? Color.orange : Color.red
    }

    private var goColor: Color {
        config.colorBlindModeEnabled ? Color.blue : Color.green
    }

    private var backgroundColor: Color {
        switch viewModel.phase {
        case .green:
            return goColor
        case .waiting, .falseStart:
            return waitingColor
        case .trialResult:
            return Color.black.opacity(0.88)
        case .ready, .finished:
            return Color.black
        }
    }

    private var topBar: some View {
        HStack {
            Text(progressText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
        }
        .accessibilityHidden(true)
    }

    private var progressText: String {
        switch viewModel.phase {
        case .ready:
            return "准备"
        case .waiting(let trialIndex):
            return "第 \(trialIndex) / \(config.trialCount) 次"
        case .green(let trialIndex):
            return "第 \(trialIndex) / \(config.trialCount) 次"
        case .falseStart(let trialIndex):
            return "第 \(trialIndex) / \(config.trialCount) 次"
        case .trialResult(let trialIndex, _):
            return "第 \(trialIndex) / \(config.trialCount) 次"
        case .finished:
            return "完成"
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.phase {
        case .ready:
            VStack(spacing: 12) {
                Text("准备开始")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.white)
                Text("点击屏幕开始")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.9))
            }

        case .waiting:
            VStack(spacing: 12) {
                Text(config.colorBlindModeEnabled ? "✋" : "等待")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(.white)
                Text("不要点击")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                Text("等屏幕变色后再点")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("等待。不要点击。等屏幕变色后再点。")

        case .green:
            VStack(spacing: 12) {
                Text(config.colorBlindModeEnabled ? "●" : "点击")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(.white)
                Text("现在点击！")
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(.white)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("现在点击。")

        case .falseStart:
            VStack(spacing: 12) {
                Text("太早了！")
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(.white)
                Text("等变色后再点击")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.9))
            }

        case .trialResult(_, let reactionMs):
            VStack(spacing: 12) {
                Text("\(reactionMs) ms")
                    .font(.system(size: 54, weight: .black))
                    .foregroundStyle(.white)
                Text("点击继续")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }

        case .finished(let session):
            ReactionTestFinishedView(
                session: session,
                onRetest: {
                    hasSavedSession = false
                    viewModel.startNewSession()
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
            default:
                Text("提示：红屏点了会判定过早，本次不计入次数。")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
        }
    }
}

private struct ReactionTestFinishedView: View {
    let session: SessionResult
    let onRetest: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Text("本轮结果")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.95))

                if let averageMs = session.averageMs {
                    Text("平均 \(averageMs) ms")
                        .font(.system(size: 46, weight: .black))
                        .foregroundStyle(.white)
                } else {
                    Text("无有效成绩")
                        .font(.system(size: 40, weight: .black))
                        .foregroundStyle(.white)
                }

                HStack(spacing: 12) {
                    if let bestMs = session.bestMs {
                        Text("最佳 \(bestMs) ms")
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    Text("过早 \(session.falseStartCount)")
                        .foregroundStyle(.white.opacity(0.9))
                }
                .font(.title3.weight(.semibold))
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("年龄参考（仅供娱乐）")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.95))
                ForEach(ReactionTestAgeReference.lines, id: \.self) { line in
                    Text(line)
                        .foregroundStyle(.white.opacity(0.9))
                }
                Text(ReactionTestAgeReference.disclaimer)
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
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        ReactionTestGameView(
            store: ReactionTestSessionStore(),
            config: ReactionTestConfig(trialCount: 5, hapticsEnabled: true, soundEnabled: false, colorBlindModeEnabled: false)
        )
    }
}
