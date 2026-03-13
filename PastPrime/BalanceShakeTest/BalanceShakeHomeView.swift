//
//  BalanceShakeHomeView.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import SwiftUI

struct BalanceShakeHomeView: View {
    @StateObject private var store = BalanceShakeSessionStore()

    @AppStorage(BalanceShakeDefaultsKeys.hapticsEnabled) private var hapticsEnabled: Bool = true
    @AppStorage(BalanceShakeDefaultsKeys.soundEnabled) private var soundEnabled: Bool = false

    private var config: BalanceShakeConfig {
        BalanceShakeConfig(hapticsEnabled: hapticsEnabled, soundEnabled: soundEnabled)
    }

    var body: some View {
        List {
            Section {
                NavigationLink {
                    BalanceShakeGameView(store: store, config: config)
                } label: {
                    Label("开始测试", systemImage: "play.fill")
                        .font(.headline)
                }
            } footer: {
                Text("校准后开始计时：尽量保持设备稳定，越久越好（默认最多 30 秒）。")
            }

            if let latest = store.sessions.first {
                Section("最近一次") {
                    NavigationLink {
                        BalanceShakeSessionDetailView(session: latest)
                    } label: {
                        BalanceShakeSessionRow(session: latest)
                    }
                }
            }

            Section("工具") {
                NavigationLink("历史记录") {
                    BalanceShakeHistoryView(store: store)
                }
                NavigationLink("设置") {
                    BalanceShakeSettingsView()
                }
            }

            Section("年龄参考（仅供娱乐）") {
                ForEach(BalanceShakeAgeReference.lines, id: \.self) { line in
                    Text(line)
                }
                Text(BalanceShakeAgeReference.disclaimer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("平衡摇晃测试")
    }
}

private struct BalanceShakeSessionRow: View {
    let session: BalanceShakeSessionResult

    var body: some View {
        let level = BalanceStabilityLevel.from(durationMs: session.durationMs)
        let seconds = Double(session.durationMs) / 1000.0

        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(session.createdAt, style: .date)
                Text(session.createdAt, style: .time)
                    .foregroundStyle(.secondary)
            }

            Text(String(format: "稳定 %.1f 秒", seconds))
                .font(.headline)

            Text("\(level.title) \(level.ageReferenceText)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        BalanceShakeHomeView()
    }
}

