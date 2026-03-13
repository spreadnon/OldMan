//
//  HearingFrequencyHomeView.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import SwiftUI

struct HearingFrequencyHomeView: View {
    @StateObject private var store = HearingFrequencySessionStore()

    @AppStorage(HearingFrequencyDefaultsKeys.hapticsEnabled) private var hapticsEnabled: Bool = true
    @AppStorage(HearingFrequencyDefaultsKeys.showCurrentFrequency) private var showCurrentFrequency: Bool = false

    private var config: HearingFrequencyConfig {
        HearingFrequencyConfig(
            hapticsEnabled: hapticsEnabled,
            showCurrentFrequency: showCurrentFrequency
        )
    }

    var body: some View {
        List {
            Section {
                NavigationLink {
                    HearingFrequencyGameView(store: store, config: config)
                } label: {
                    Label("开始测试", systemImage: "play.fill")
                        .font(.headline)
                }
            } footer: {
                Text("建议佩戴耳机，音量从低开始。听到声音时立刻点击停止。")
            }

            if let latest = store.sessions.first {
                Section("最近一次") {
                    NavigationLink {
                        HearingFrequencySessionDetailView(session: latest)
                    } label: {
                        HearingFrequencySessionRow(session: latest)
                    }
                }
            }

            Section("工具") {
                NavigationLink("历史记录") {
                    HearingFrequencyHistoryView(store: store)
                }
                NavigationLink("设置") {
                    HearingFrequencySettingsView()
                }
            }

            Section("年龄参考（仅供娱乐）") {
                ForEach(HearingFrequencyAgeReference.lines, id: \.self) { line in
                    Text(line)
                }
                Text(HearingFrequencyAgeReference.disclaimer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("听力频率测试")
    }
}

private struct HearingFrequencySessionRow: View {
    let session: HearingFrequencySessionResult

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(session.createdAt, style: .date)
                Text(session.createdAt, style: .time)
                    .foregroundStyle(.secondary)
            }

            if let hz = session.detectedHz {
                let level = HearingFrequencyLevel.from(detectedHz: hz)
                Text("最高可听 \(formatHz(hz))")
                    .font(.headline)
                Text("\(level.ageReferenceText)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("未检测到（未点击停止）")
                    .font(.headline)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatHz(_ hz: Int) -> String {
        String(format: "%.1f kHz", Double(hz) / 1000.0)
    }
}

#Preview {
    NavigationStack {
        HearingFrequencyHomeView()
    }
}
