//
//  ReactionTestInfoView.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import SwiftUI

struct ReactionTestInfoView: View {
    @ObservedObject var store: ReactionTestSessionStore
    let config: ReactionTestConfig

    var body: some View {
        List {
            Section("怎么玩") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1) 红屏等待（不要点击）")
                    Text("2) 变绿后立刻点击屏幕")
                    Text("3) 重复 \(config.trialCount) 次，取成功试次的平均毫秒")
                    Text("红屏点击会判定为过早，本次不计入次数。")
                        .foregroundStyle(.secondary)
                }
            }

            if let latest = store.sessions.first {
                Section("最近一次") {
                    NavigationLink {
                        ReactionTestSessionDetailView(session: latest)
                    } label: {
                        ReactionTestInfoSessionRow(session: latest)
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
        .navigationTitle("反应速度说明")
    }
}

private struct ReactionTestInfoSessionRow: View {
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
        ReactionTestInfoView(
            store: ReactionTestSessionStore(),
            config: ReactionTestConfig(trialCount: 5, hapticsEnabled: true, soundEnabled: false, colorBlindModeEnabled: false)
        )
    }
}

