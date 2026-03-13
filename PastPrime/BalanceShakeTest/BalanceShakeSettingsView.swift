//
//  BalanceShakeSettingsView.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import SwiftUI

struct BalanceShakeSettingsView: View {
    @AppStorage(BalanceShakeDefaultsKeys.hapticsEnabled) private var hapticsEnabled: Bool = true
    @AppStorage(BalanceShakeDefaultsKeys.soundEnabled) private var soundEnabled: Bool = false

    var body: some View {
        Form {
            Section("反馈") {
                Toggle("震动反馈", isOn: $hapticsEnabled)
                Toggle("声音提示", isOn: $soundEnabled)
            }

            Section("说明") {
                Text("该测试会读取设备姿态/加速度用于计算稳定性，不会上传。")
                Text(BalanceShakeAgeReference.disclaimer)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("设置")
    }
}

#Preview {
    NavigationStack {
        BalanceShakeSettingsView()
    }
}

