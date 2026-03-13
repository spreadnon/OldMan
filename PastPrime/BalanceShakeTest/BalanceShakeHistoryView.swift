//
//  BalanceShakeHistoryView.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import SwiftUI

struct BalanceShakeHistoryView: View {
    @ObservedObject var store: BalanceShakeSessionStore
    @State private var showClearConfirm: Bool = false

    var body: some View {
        List {
            if store.sessions.isEmpty {
                ContentUnavailableView("暂无记录", systemImage: "clock")
            } else {
                ForEach(store.sessions) { session in
                    NavigationLink {
                        BalanceShakeSessionDetailView(session: session)
                    } label: {
                        BalanceShakeHistoryRow(session: session)
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

private struct BalanceShakeHistoryRow: View {
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
        BalanceShakeHistoryView(store: BalanceShakeSessionStore())
    }
}

