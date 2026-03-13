//
//  ReactionTestHistoryView.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import SwiftUI

struct ReactionTestHistoryView: View {
    @ObservedObject var store: ReactionTestSessionStore
    @State private var showClearConfirm: Bool = false

    var body: some View {
        List {
            if store.sessions.isEmpty {
                ContentUnavailableView("暂无记录", systemImage: "clock")
            } else {
                ForEach(store.sessions) { session in
                    NavigationLink {
                        ReactionTestSessionDetailView(session: session)
                    } label: {
                        ReactionTestHistoryRow(session: session)
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

private struct ReactionTestHistoryRow: View {
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
                Text("\(session.trialCount) 次")
                    .foregroundStyle(.secondary)
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
        ReactionTestHistoryView(store: ReactionTestSessionStore())
    }
}

