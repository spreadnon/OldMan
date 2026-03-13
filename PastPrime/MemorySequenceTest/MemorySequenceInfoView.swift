//
//  MemorySequenceInfoView.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import SwiftUI

struct MemorySequenceInfoView: View {
    @ObservedObject var store: MemorySequenceSessionStore
    let config: MemorySequenceConfig

    var body: some View {
        List {
            Section("怎么玩") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1) 观察方块亮起顺序")
                    Text("2) 按相同顺序点击复现")
                    Text("3) 每过一关会增加 1 项，直到出错为止")
                }
            }

            if let latest = store.sessions.first {
                Section("最近一次") {
                    NavigationLink {
                        MemorySequenceSessionDetailView(session: latest)
                    } label: {
                        MemorySequenceInfoSessionRow(session: latest)
                    }
                }
            }

            Section("工具") {
                NavigationLink("历史记录") {
                    MemorySequenceHistoryView(store: store)
                }
                NavigationLink("设置") {
                    MemorySequenceSettingsView()
                }
            }

            Section("年龄参考（仅供娱乐）") {
                ForEach(MemorySequenceAgeReference.lines, id: \.self) { line in
                    Text(line)
                }
                Text(MemorySequenceAgeReference.disclaimer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("记忆力说明")
    }
}

private struct MemorySequenceInfoSessionRow: View {
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
        MemorySequenceInfoView(store: MemorySequenceSessionStore(), config: MemorySequenceConfig(hapticsEnabled: true))
    }
}

