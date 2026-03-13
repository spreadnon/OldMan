//
//  ReactionTestSettingsView.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import SwiftUI

struct ReactionTestSettingsView: View {
    @AppStorage(ReactionTestDefaultsKeys.trialCount) private var trialCount: Int = 5
    @AppStorage(ReactionTestDefaultsKeys.hapticsEnabled) private var hapticsEnabled: Bool = true
    @AppStorage(ReactionTestDefaultsKeys.soundEnabled) private var soundEnabled: Bool = false
    @AppStorage(ReactionTestDefaultsKeys.colorBlindModeEnabled) private var colorBlindModeEnabled: Bool = false

    var body: some View {
        Form {
            Section("测试") {
                Stepper(value: $trialCount, in: 5...10, step: 1) {
                    Text("试次数：\(trialCount) 次")
                }

                Toggle("震动反馈", isOn: $hapticsEnabled)
                Toggle("声音提示", isOn: $soundEnabled)
                Toggle("色弱模式", isOn: $colorBlindModeEnabled)
            }

            Section("说明") {
                Text("色弱模式会使用更容易区分的配色，并同时显示文字/符号提示。")
                Text(ReactionTestAgeReference.disclaimer)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("设置")
    }
}

#Preview {
    NavigationStack {
        ReactionTestSettingsView()
    }
}

