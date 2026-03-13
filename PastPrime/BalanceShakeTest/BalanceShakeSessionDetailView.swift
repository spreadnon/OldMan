//
//  BalanceShakeSessionDetailView.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import SwiftUI

struct BalanceShakeSessionDetailView: View {
    let session: BalanceShakeSessionResult

    var body: some View {
        let seconds = Double(session.durationMs) / 1000.0
        let level = BalanceStabilityLevel.from(durationMs: session.durationMs)

        return List {
            Section("概览") {
                LabeledContent("时间") {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(session.createdAt, style: .date)
                        Text(session.createdAt, style: .time)
                            .foregroundStyle(.secondary)
                    }
                }

                LabeledContent("稳定时间") {
                    Text(String(format: "%.1f 秒", seconds))
                }

                LabeledContent("稳定性") {
                    Text("\(level.title) \(level.ageReferenceText)")
                }

                LabeledContent("结束原因") {
                    Text(endReasonText(session.endReason))
                        .foregroundStyle(.secondary)
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
        .navigationTitle("测试详情")
    }

    private func endReasonText(_ reason: BalanceShakeEndReason) -> String {
        switch reason {
        case .wobble:
            return "出现大晃动"
        case .reachedMaxTime:
            return "达到上限时间"
        case .cancelled:
            return "已取消"
        }
    }
}

#Preview {
    NavigationStack {
        BalanceShakeSessionDetailView(
            session: BalanceShakeSessionResult(durationMs: 18_500, maxDeviationRad: 0.2, endReason: .wobble)
        )
    }
}

