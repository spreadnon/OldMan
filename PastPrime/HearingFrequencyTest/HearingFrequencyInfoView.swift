//
//  HearingFrequencyInfoView.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import SwiftUI

struct HearingFrequencyInfoView: View {
    @ObservedObject var store: HearingFrequencySessionStore
    let config: HearingFrequencyConfig

    var body: some View {
        List {
            Section("怎么玩") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1) 建议佩戴耳机，音量从低开始")
                    Text("2) 点击开始后从高频逐渐降低")
                    Text("3) 听到声音时立刻点击停止，记录最高可听频率")
                    Text("安全提示：请勿将音量调得过大；如不适请立即停止。")
                        .foregroundStyle(.secondary)
                }
            }

            if let latest = store.sessions.first {
                Section("最近一次") {
                    NavigationLink {
                        HearingFrequencySessionDetailView(session: latest)
                    } label: {
                        HearingFrequencyInfoSessionRow(session: latest)
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
        .navigationTitle("听力频率说明")
    }
}

private struct HearingFrequencyInfoSessionRow: View {
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
                Text("未检测到")
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
        HearingFrequencyInfoView(
            store: HearingFrequencySessionStore(),
            config: HearingFrequencyConfig(hapticsEnabled: true, showCurrentFrequency: false)
        )
    }
}

