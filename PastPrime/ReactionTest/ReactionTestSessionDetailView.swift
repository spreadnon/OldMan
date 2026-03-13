//
//  ReactionTestSessionDetailView.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import SwiftUI

struct ReactionTestSessionDetailView: View {
    let session: SessionResult

    var body: some View {
        List {
            Section("概览") {
                LabeledContent("时间") {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(session.createdAt, style: .date)
                        Text(session.createdAt, style: .time)
                            .foregroundStyle(.secondary)
                    }
                }

                LabeledContent("试次数") {
                    Text("\(session.trialCount)")
                }

                if let averageMs = session.averageMs {
                    LabeledContent("平均") { Text("\(averageMs) ms") }
                }
                if let bestMs = session.bestMs {
                    LabeledContent("最佳") { Text("\(bestMs) ms") }
                }

                LabeledContent("过早点击") {
                    Text("\(session.falseStartCount)")
                }
            }

            Section("每次明细") {
                ForEach(session.trials.sorted(by: { $0.index < $1.index })) { trial in
                    HStack {
                        Text("第 \(trial.index) 次")
                        Spacer()
                        if let reactionMs = trial.reactionMs {
                            Text("\(reactionMs) ms")
                                .font(.headline)
                        } else {
                            Text(trial.outcome.rawValue)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("年龄参考（仅供娱乐）") {
                ForEach(ReactionTestAgeReference.lines, id: \.self) { line in
                    Text(line)
                }
                Text(ReactionTestAgeReference.disclaimer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("测试详情")
    }
}

#Preview {
    NavigationStack {
        ReactionTestSessionDetailView(
            session: SessionResult(
                trialCount: 5,
                trials: (1...5).map { TrialResult(index: $0, outcome: .success, reactionMs: 200 + $0 * 10, waitDelayMs: 2000) },
                averageMs: 230,
                bestMs: 210,
                falseStartCount: 1
            )
        )
    }
}

