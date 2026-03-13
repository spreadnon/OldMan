//
//  BalanceShakeInfoView.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import SwiftUI

struct BalanceShakeInfoView: View {
    @ObservedObject var store: BalanceShakeSessionStore
    let config: BalanceShakeConfig

    var body: some View {
        List {
            Section("怎么玩") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1) 进入后会先校准（请保持静止）")
                    Text("2) 校准完成开始计时，尽量保持设备稳定")
                    Text("3) 出现持续大晃动会结束，记录稳定时间")
                    Text("提示：建议真机运行；模拟器可拖动圆点进行模拟。")
                        .foregroundStyle(.secondary)
                }
            }

            if let latest = store.sessions.first {
                Section("最近一次") {
                    NavigationLink {
                        BalanceShakeSessionDetailView(session: latest)
                    } label: {
                        BalanceShakeInfoSessionRow(session: latest)
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
        .navigationTitle("平衡摇晃说明")
    }
}

private struct BalanceShakeInfoSessionRow: View {
    let session: BalanceShakeSessionResult

    var body: some View {
        let seconds = Double(session.durationMs) / 1000.0
        let level = BalanceStabilityLevel.from(durationMs: session.durationMs)

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
        BalanceShakeInfoView(
            store: BalanceShakeSessionStore(),
            config: BalanceShakeConfig(hapticsEnabled: true, soundEnabled: false)
        )
    }
}

