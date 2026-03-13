//
//  MemorySequenceSessionDetailView.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import SwiftUI

struct MemorySequenceSessionDetailView: View {
    let session: MemorySequenceSessionResult

    var body: some View {
        let level = MemorySequenceLevel.from(bestItems: session.bestItems)

        return List {
            Section("概览") {
                LabeledContent("时间") {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(session.createdAt, style: .date)
                        Text(session.createdAt, style: .time)
                            .foregroundStyle(.secondary)
                    }
                }

                LabeledContent("最高记住") {
                    Text("\(session.bestItems) 项")
                        .font(.headline)
                }

                LabeledContent("参考年龄") {
                    Text(level.ageReferenceText)
                }

                LabeledContent("起始项数") {
                    Text("\(session.startItems)")
                        .foregroundStyle(.secondary)
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
        .navigationTitle("测试详情")
    }
}

#Preview {
    NavigationStack {
        MemorySequenceSessionDetailView(
            session: MemorySequenceSessionResult(bestItems: 7, startItems: 3, reachedItems: 8, endReason: .failed)
        )
    }
}

