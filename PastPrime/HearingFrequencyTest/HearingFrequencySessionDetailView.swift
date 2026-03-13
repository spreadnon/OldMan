//
//  HearingFrequencySessionDetailView.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import SwiftUI

struct HearingFrequencySessionDetailView: View {
    let session: HearingFrequencySessionResult

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

                LabeledContent("输出设备") {
                    Text(session.outputRoute)
                        .foregroundStyle(.secondary)
                }

                LabeledContent("测试频段") {
                    Text("\(session.startHz) → \(session.endHz) Hz")
                        .foregroundStyle(.secondary)
                }

                if let hz = session.detectedHz {
                    let level = HearingFrequencyLevel.from(detectedHz: hz)
                    LabeledContent("最高可听频率") {
                        Text(formatHz(hz))
                            .font(.headline)
                    }
                    LabeledContent("参考年龄") {
                        Text(level.ageReferenceText)
                    }
                } else {
                    LabeledContent("结果") {
                        Text("未检测到")
                            .font(.headline)
                    }
                    LabeledContent("提示") {
                        Text("可能音量过低 / 未佩戴耳机 / 未点击停止")
                            .foregroundStyle(.secondary)
                    }
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
        .navigationTitle("测试详情")
    }

    private func formatHz(_ hz: Int) -> String {
        String(format: "%.1f kHz", Double(hz) / 1000.0)
    }
}

#Preview {
    NavigationStack {
        HearingFrequencySessionDetailView(
            session: HearingFrequencySessionResult(
                detectedHz: 12_500,
                durationMs: 2500,
                startHz: 18_000,
                endHz: 2_000,
                outputRoute: "headphones",
                endReason: .stoppedByUser
            )
        )
    }
}

