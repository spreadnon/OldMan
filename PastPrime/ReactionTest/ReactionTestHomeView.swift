//
//  ReactionTestHomeView.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import SwiftUI

struct ReactionTestHomeView: View {
    @StateObject private var store = ReactionTestSessionStore()

    @AppStorage(ReactionTestDefaultsKeys.trialCount) private var trialCount: Int = 5
    @AppStorage(ReactionTestDefaultsKeys.hapticsEnabled) private var hapticsEnabled: Bool = true
    @AppStorage(ReactionTestDefaultsKeys.soundEnabled) private var soundEnabled: Bool = false
    @AppStorage(ReactionTestDefaultsKeys.colorBlindModeEnabled) private var colorBlindModeEnabled: Bool = false

    private var config: ReactionTestConfig {
        ReactionTestConfig(
            trialCount: min(max(trialCount, 5), 10),
            hapticsEnabled: hapticsEnabled,
            soundEnabled: soundEnabled,
            colorBlindModeEnabled: colorBlindModeEnabled
        )
    }

    var body: some View {
        List {
            Section {
                NavigationLink {
                    ReactionTestGameView(store: store, config: config)
                } label: {
                    Label("开始测试", systemImage: "play.fill")
                        .font(.headline)
                }
            } footer: {
                Text("红屏等待 → 变绿立刻点击，重复 \(config.trialCount) 次取平均。")
            }

            if let latest = store.sessions.first {
                Section("最近一次") {
                    NavigationLink {
                        ReactionTestSessionDetailView(session: latest)
                    } label: {
                        ReactionTestSessionRow(session: latest)
                    }
                }
            }

            Section("工具") {
                NavigationLink("历史记录") {
                    ReactionTestHistoryView(store: store)
                }
                NavigationLink("设置") {
                    ReactionTestSettingsView()
                }
            }

            Section("年龄参考（仅供娱乐）") {
                ForEach(ReactionTestAgeReference.lines, id: \.self) { line in
                    Text(line)
                }
                Text(ReactionTestAgeReference.disclaimer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("反应速度测试")
    }
}

private struct ReactionTestSessionRow: View {
    let session: SessionResult

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(session.createdAt, style: .date)
                Text(session.createdAt, style: .time)
                    .foregroundStyle(.secondary)
            }

            if let averageMs = session.averageMs {
                Text("平均 \(averageMs) ms")
                    .font(.headline)
            } else {
                Text("无有效成绩")
                    .font(.headline)
            }

            HStack(spacing: 10) {
                if let bestMs = session.bestMs {
                    Text("最佳 \(bestMs) ms")
                        .foregroundStyle(.secondary)
                }
                Text("过早 \(session.falseStartCount)")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ReactionTestHomeView()
    }
}
