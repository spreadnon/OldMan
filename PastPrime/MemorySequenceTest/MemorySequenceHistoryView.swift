//
//  MemorySequenceHistoryView.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import SwiftUI

struct MemorySequenceHistoryView: View {
    @ObservedObject var store: MemorySequenceSessionStore
    @State private var showClearConfirm: Bool = false

    var body: some View {
        List {
            if store.sessions.isEmpty {
                ContentUnavailableView("暂无记录", systemImage: "clock")
            } else {
                ForEach(store.sessions) { session in
                    NavigationLink {
                        MemorySequenceSessionDetailView(session: session)
                    } label: {
                        MemorySequenceHistoryRow(session: session)
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

private struct MemorySequenceHistoryRow: View {
    let session: MemorySequenceSessionResult

    var body: some View {
        let level = MemorySequenceLevel.from(bestItems: session.bestItems)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(session.createdAt, style: .date)
                Text(session.createdAt, style: .time)
                    .foregroundStyle(.secondary)
            }

            Text("最高 \(session.bestItems) 项")
                .font(.headline)

            Text(level.ageReferenceText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        MemorySequenceHistoryView(store: MemorySequenceSessionStore())
    }
}

