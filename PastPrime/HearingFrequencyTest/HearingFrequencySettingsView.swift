//
//  HearingFrequencySettingsView.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import SwiftUI

struct HearingFrequencySettingsView: View {
    @AppStorage(HearingFrequencyDefaultsKeys.hapticsEnabled) private var hapticsEnabled: Bool = true
    @AppStorage(HearingFrequencyDefaultsKeys.showCurrentFrequency) private var showCurrentFrequency: Bool = false

    var body: some View {
        Form {
            Section("显示") {
                Toggle("显示实时频率", isOn: $showCurrentFrequency)
            }

            Section("反馈") {
                Toggle("震动反馈", isOn: $hapticsEnabled)
            }

            Section("说明") {
                Text("请勿将音量调得过大。建议佩戴耳机并在安静环境测试。")
                Text(HearingFrequencyAgeReference.disclaimer)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("设置")
    }
}

#Preview {
    NavigationStack {
        HearingFrequencySettingsView()
    }
}

