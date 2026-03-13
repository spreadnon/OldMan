//
//  MemorySequenceGameView.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import SwiftUI

struct MemorySequenceGameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @ObservedObject var store: MemorySequenceSessionStore
    let config: MemorySequenceConfig

    @StateObject private var viewModel: MemorySequenceViewModel
    @State private var hasSavedSession: Bool = false

    init(store: MemorySequenceSessionStore, config: MemorySequenceConfig) {
        self.store = store
        self.config = config
        _viewModel = StateObject(wrappedValue: MemorySequenceViewModel(config: config))
    }

    var body: some View {
        ZStack {
//            Color.black.ignoresSafeArea()
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color(red: 66/255, green: 52/255, blue: 48/255)]),
                startPoint: .bottomTrailing,
                endPoint: .topLeading
            ).ignoresSafeArea()

            VStack(spacing: 16) {
                topBar
                Spacer()
                grid
                Spacer()
                footer
            }
            .padding(16)
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
            ToolbarItem(placement: .topBarLeading) {
                Button("重开") {
                    hasSavedSession = false
                    viewModel.start()
                }
                .disabled(viewModel.isInProgress)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
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
        .onAppear {
            hasSavedSession = false
        }
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("记忆力序列")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.95))
                Text(bestText)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
            }
            Spacer()
            Text(phaseText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .accessibilityHidden(true)
    }

    private var bestText: String {
        if viewModel.bestItems > 0 {
            return "本轮最好：\(viewModel.bestItems) 项"
        }
        return "本轮最好：--"
    }

    private var phaseText: String {
        switch viewModel.phase {
        case .ready:
            return "准备"
        case .showing(let items):
            return "观察 \(items) 项"
        case .input(let items, let progress):
            return "复现 \(progress)/\(items)"
        case .finished:
            return "完成"
        }
    }

    private var grid: some View {
        let side = config.gridSide
        let count = side * side
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: side)

        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(0..<count, id: \.self) { index in
                Button {
                    viewModel.handleTap(index: index)
                } label: {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tileColor(index: index))
                        .frame(height: 78)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .disabled(!isTileEnabled)
            }
        }
        .animation(.easeInOut(duration: 0.12), value: viewModel.highlightedIndex)
        .animation(.easeInOut(duration: 0.12), value: viewModel.tapFlashIndex)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var isTileEnabled: Bool {
        if case .input = viewModel.phase {
            return true
        }
        return false
    }

    private func tileColor(index: Int) -> Color {
        if viewModel.highlightedIndex == index {
            return .white.opacity(0.95)
        }
        if viewModel.tapFlashIndex == index {
            return .blue.opacity(0.9)
        }
        return .white.opacity(0.12)
    }

    private var accessibilityLabel: String {
        switch viewModel.phase {
        case .ready:
            return "准备开始。"
        case .showing:
            return "正在展示序列。"
        case .input(let items, let progress):
            return "请复现序列。已输入 \(progress) 项，共 \(items) 项。"
        case .finished:
            return "测试完成。"
        }
    }

    @ViewBuilder
    private var footer: some View {
        switch viewModel.phase {
        case .ready:
            VStack(spacing: 10) {
                Text("记住方块亮起顺序\n然后按相同顺序点击")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.85))

                Button {
                    hasSavedSession = false
                    viewModel.start()
                } label: {
                    Text("开始")
                        .frame(maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.2))
                .foregroundStyle(.white)
            }

        case .showing:
            Text("观察中…")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))

        case .input:
            Text("现在按顺序点回去")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))

        case .finished(let session):
            MemorySequenceFinishedView(session: session) {
                hasSavedSession = false
                viewModel.start()
            } onDone: {
                dismiss()
            }
        }
    }
}

private struct MemorySequenceFinishedView: View {
    let session: MemorySequenceSessionResult
    let onRetest: () -> Void
    let onDone: () -> Void

    var body: some View {
        let level = MemorySequenceLevel.from(bestItems: session.bestItems)

        return VStack(spacing: 18) {
            Text("本轮结果")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.95))

            Text("最高 \(session.bestItems) 项")
                .font(.system(size: 44, weight: .black))
                .foregroundStyle(.white)

            Text(level.ageReferenceText)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))

            VStack(alignment: .leading, spacing: 12) {
                Text("年龄参考（仅供娱乐）")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.95))
                ForEach(MemorySequenceAgeReference.lines, id: \.self) { line in
                    Text(line)
                        .foregroundStyle(.white.opacity(0.9))
                }
                Text(MemorySequenceAgeReference.disclaimer)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                Button(action: onRetest) {
                    Text("再测一次")
                        .frame(maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.25))

                Button(action: onDone) {
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
        MemorySequenceGameView(store: MemorySequenceSessionStore(), config: MemorySequenceConfig(hapticsEnabled: true))
    }
}
