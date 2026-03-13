//
//  MemorySequenceSettingsView.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import SwiftUI

struct MemorySequenceSettingsView: View {
    @AppStorage(MemorySequenceDefaultsKeys.hapticsEnabled) private var hapticsEnabled: Bool = true

    var body: some View {
        Form {
            Section("反馈") {
                Toggle("震动反馈", isOn: $hapticsEnabled)
            }

            Section("说明") {
                Text("记忆力测试会逐步增加序列长度，直到出错为止。")
                Text(MemorySequenceAgeReference.disclaimer)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("设置")
    }
}

#Preview {
    NavigationStack {
        MemorySequenceSettingsView()
    }
}

