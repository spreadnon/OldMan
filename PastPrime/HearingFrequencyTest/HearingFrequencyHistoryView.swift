//
//  HearingFrequencyHistoryView.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import SwiftUI

struct HearingFrequencyHistoryView: View {
    @ObservedObject var store: HearingFrequencySessionStore
    @State private var showClearConfirm: Bool = false

    var body: some View {
        List {
            if store.sessions.isEmpty {
                ContentUnavailableView("暂无记录", systemImage: "clock")
            } else {
                ForEach(store.sessions) { session in
                    NavigationLink {
                        HearingFrequencySessionDetailView(session: session)
                    } label: {
                        HearingFrequencyHistoryRow(session: session)
                    }
                }
            }
        }
        .navigationTitle("历史记录")
        .toolbar {
            if !store.sessions.isEmpty {
                Button("清空") {
                    showClearConfirm = true
                }
            }
        }
        .confirmationDialog("确认清空全部历史记录？", isPresented: $showClearConfirm) {
            Button("清空", role: .destructive) {
                store.clear()
            }
            Button("取消", role: .cancel) {}
        }
    }
}

private struct HearingFrequencyHistoryRow: View {
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
        HearingFrequencyHistoryView(store: HearingFrequencySessionStore())
    }
}

