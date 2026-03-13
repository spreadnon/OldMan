//
//  PastPrimeHomeView.swift
//  PastPrime
//
//  Created by Jeremy chen on 2026/3/12.
//

import SwiftUI

struct PastPrimeHomeView: View {
    @StateObject private var reactionStore = ReactionTestSessionStore()
    @StateObject private var balanceStore = BalanceShakeSessionStore()
    @StateObject private var hearingStore = HearingFrequencySessionStore()
    @StateObject private var memoryStore = MemorySequenceSessionStore()

    @AppStorage(ReactionTestDefaultsKeys.trialCount) private var reactionTrialCount: Int = 5
    @AppStorage(ReactionTestDefaultsKeys.hapticsEnabled) private var reactionHapticsEnabled: Bool = true
    @AppStorage(ReactionTestDefaultsKeys.soundEnabled) private var reactionSoundEnabled: Bool = false
    @AppStorage(ReactionTestDefaultsKeys.colorBlindModeEnabled) private var reactionColorBlindModeEnabled: Bool = false

    @AppStorage(BalanceShakeDefaultsKeys.hapticsEnabled) private var balanceHapticsEnabled: Bool = true
    @AppStorage(BalanceShakeDefaultsKeys.soundEnabled) private var balanceSoundEnabled: Bool = false

    @AppStorage(HearingFrequencyDefaultsKeys.hapticsEnabled) private var hearingHapticsEnabled: Bool = true
    @AppStorage(HearingFrequencyDefaultsKeys.showCurrentFrequency) private var hearingShowCurrentFrequency: Bool = false

    @AppStorage(MemorySequenceDefaultsKeys.hapticsEnabled) private var memoryHapticsEnabled: Bool = true

    @State private var activeSheet: PastPrimeSheet?

    private enum PastPrimeSheet: Identifiable {
        case reactionGame
        case reactionInfo
        case balanceGame
        case balanceInfo
        case hearingGame
        case hearingInfo
        case memoryGame
        case memoryInfo

        var id: String {
            switch self {
            case .reactionGame: return "reactionGame"
            case .reactionInfo: return "reactionInfo"
            case .balanceGame: return "balanceGame"
            case .balanceInfo: return "balanceInfo"
            case .hearingGame: return "hearingGame"
            case .hearingInfo: return "hearingInfo"
            case .memoryGame: return "memoryGame"
            case .memoryInfo: return "memoryInfo"
            }
        }
    }

    private var reactionConfig: ReactionTestConfig {
        ReactionTestConfig(
            trialCount: min(max(reactionTrialCount, 5), 10),
            hapticsEnabled: reactionHapticsEnabled,
            soundEnabled: reactionSoundEnabled,
            colorBlindModeEnabled: reactionColorBlindModeEnabled
        )
    }

    private var balanceConfig: BalanceShakeConfig {
        BalanceShakeConfig(hapticsEnabled: balanceHapticsEnabled, soundEnabled: balanceSoundEnabled)
    }

    private var hearingConfig: HearingFrequencyConfig {
        HearingFrequencyConfig(hapticsEnabled: hearingHapticsEnabled, showCurrentFrequency: hearingShowCurrentFrequency)
    }

    private var memoryConfig: MemorySequenceConfig {
        MemorySequenceConfig(hapticsEnabled: memoryHapticsEnabled)
    }

    private var overallScore: Double {
        var scores: [Double] = []
        if let averageMs = reactionStore.sessions.first?.averageMs {
            scores.append(PastPrimeScore.reaction(averageMs: averageMs))
        }
        if let balance = balanceStore.sessions.first {
            scores.append(PastPrimeScore.balance(durationMs: balance.durationMs))
        }
        if let hz = hearingStore.sessions.first?.detectedHz {
            scores.append(PastPrimeScore.hearing(detectedHz: hz))
        }
        if let bestItems = memoryStore.sessions.first?.bestItems {
            scores.append(PastPrimeScore.memory(bestItems: bestItems))
        }
        return PastPrimeScore.overall(scores: scores) ?? 0
    }

    private var rank: PastPrimeRank {
        PastPrimeRank.from(score: overallScore)
    }

    private var rankTitle: String {
        if overallScore == 0 {
            return "测测你老登了么？"
        }
        return rank.rawValue
    }

    private var scoreTitle: String {
        return String(Int(overallScore.rounded()))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    PastPrimeRankCard(title: rankTitle, score: scoreTitle, tint: rank.tint)
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        .listRowBackground(Color.clear)
                }
                
                Section {
                    VStack(spacing: 16) {
                        PastPrimeGameCard(
                            title: "反应速度",
                            desc: "捕捉颜色变化的瞬间神经反射",
                            latest: reactionLatestText,
                            imageName: "",
                            tint: .pink,
                            isFullWidth: true,
                            customBackground: AnyView(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.clear, Color(red: 49/255, green: 56/255, blue: 41/255)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            ),
                            onStart: { activeSheet = .reactionGame },
                            onInfo: { activeSheet = .reactionInfo }
                        )
                        
                        HStack(spacing: 16) {
                            PastPrimeGameCard(
                                title: "平衡摇晃",
                                desc: "手持设备挑战极限平衡",
                                latest: balanceLatestText,
                                imageName: "",
                                tint: .green,
                                isFullWidth: false,
                                customBackground: AnyView(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.clear, Color(red: 57/255, green: 70/255, blue: 83/255)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                ),
                                onStart: { activeSheet = .balanceGame },
                                onInfo: { activeSheet = .balanceInfo }
                            )
                            
                            PastPrimeGameCard(
                                title: "听力频率",
                                desc: "探索你耳朵能听到的高频极限",
                                latest: hearingLatestText,
                                imageName: "",
                                tint: .yellow,
                                isFullWidth: false,
                                customBackground: AnyView(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.clear, Color(red: 70/255, green: 68/255, blue: 38/255)]),
                                        startPoint: .bottomTrailing,
                                        endPoint: .topLeading
                                    )
                                ),
                                onStart: { activeSheet = .hearingGame },
                                onInfo: { activeSheet = .hearingInfo }
                            )
                        }
                        
                        PastPrimeGameCard(
                            title: "记忆力序列",
                            desc: "记忆并重现不断增加的图案序列",
                            latest: memoryLatestText,
                            imageName: "",
                            tint: .blue,
                            isFullWidth: true,
                            customBackground: AnyView(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.clear, Color(red: 66/255, green: 52/255, blue: 48/255)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            ),
                            onStart: { activeSheet = .memoryGame },
                            onInfo: { activeSheet = .memoryInfo }
                        )
                    }
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 20, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                header: {
                    HStack(alignment: .center, spacing: 10) {
                        Text("扳回一局？")
                        Spacer()
                    }
                    .textCase(nil)
                }
                
                Section {
                    Text("提示：所有结果仅供娱乐参考，受设备与状态影响。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("PastPrime")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        reactionStore.clear()
                        balanceStore.clear()
                        hearingStore.clear()
                        memoryStore.clear()
                    } label: {
                        HStack(spacing: 6) {
                                Text("重置")
                                Image(systemName: "gobackward")
                                .font(.system(size: 13))
                            }.foregroundColor(.white)
                    }.tint(.white)
                }
            }
            
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .reactionGame:
                NavigationStack {
                    ReactionTestGameView(store: reactionStore, config: reactionConfig)
                }
                .presentationDetents([.large])

            case .balanceGame:
                NavigationStack {
                    BalanceShakeGameView(store: balanceStore, config: balanceConfig)
                }
                .presentationDetents([.large])

            case .hearingGame:
                NavigationStack {
                    HearingFrequencyGameView(store: hearingStore, config: hearingConfig)
                }
                .presentationDetents([.large])

            case .memoryGame:
                NavigationStack {
                    MemorySequenceGameView(store: memoryStore, config: memoryConfig)
                }
                .presentationDetents([.large])

            case .reactionInfo:
                NavigationStack {
                    ReactionTestInfoView(store: reactionStore, config: reactionConfig)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    activeSheet = nil
                                } label: {
                                    Label("关闭", systemImage: "xmark.circle.fill")
                                        .labelStyle(.iconOnly)
                                        .foregroundColor(.white)
                                }.tint(.white)
                            }
                        }
                }
                .presentationDetents([.medium, .large])

            case .balanceInfo:
                NavigationStack {
                    BalanceShakeInfoView(store: balanceStore, config: balanceConfig)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    activeSheet = nil
                                } label: {
                                    Label("关闭", systemImage: "xmark.circle.fill")
                                        .labelStyle(.iconOnly)
                                        .foregroundColor(.white)
                                }.tint(.white)
                            }
                        }
                }
                .presentationDetents([.medium, .large])

            case .hearingInfo:
                NavigationStack {
                    HearingFrequencyInfoView(store: hearingStore, config: hearingConfig)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    activeSheet = nil
                                } label: {
                                    Label("关闭", systemImage: "xmark.circle.fill")
                                        .labelStyle(.iconOnly)
                                        .foregroundColor(.white)
                                }.tint(.white)
                            }
                        }
                }
                .presentationDetents([.medium, .large])

            case .memoryInfo:
                NavigationStack {
                    MemorySequenceInfoView(store: memoryStore, config: memoryConfig)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    activeSheet = nil
                                } label: {
                                    Label("关闭", systemImage: "xmark.circle.fill")
                                        .labelStyle(.iconOnly)
                                        .foregroundColor(.white)
                                }.tint(.white)
                            }
                        }
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    private var reactionLatestText: String {
        guard let latest = reactionStore.sessions.first else { return "未测试" }
        if let avg = latest.averageMs {
            if let best = latest.bestMs {
                return "平均 \(avg) ms · 最佳 \(best) ms · 过早 \(latest.falseStartCount)"
            }
            return "平均 \(avg) ms · 过早 \(latest.falseStartCount)"
        }
        return "无有效成绩 · 过早 \(latest.falseStartCount)"
    }

    private var balanceLatestText: String {
        guard let latest = balanceStore.sessions.first else { return "未测试" }
        let seconds = Double(latest.durationMs) / 1000.0
        let level = BalanceStabilityLevel.from(durationMs: latest.durationMs)
        return String(format: "稳定 %.1f 秒 · %@", seconds, level.title)
    }

    private var hearingLatestText: String {
        guard let latest = hearingStore.sessions.first else { return "未测试" }
        if let hz = latest.detectedHz {
            return String(format: "最高可听 %.1f kHz", Double(hz) / 1000.0)
        }
        return "未检测到（未点击停止）"
    }

    private var memoryLatestText: String {
        guard let latest = memoryStore.sessions.first else { return "未测试" }
        let level = MemorySequenceLevel.from(bestItems: latest.bestItems)
        return "最高 \(latest.bestItems) 项 · \(level.title)"
    }
}

#Preview {
    PastPrimeHomeView()
}

private struct PastPrimeRankCard: View {
    let title: String
    let score: String
    let tint: Color
    
    @State private var isBreathing: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(score)
                    .font(.system(size: 60, weight: .black, design: .rounded))
                Text("分")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .strokeBorder(tint.opacity(isBreathing ? 0.4 : 0.15), lineWidth: isBreathing ? 14 : 10)
                .shadow(color: tint.opacity(isBreathing ? 0.5 : 0.0), radius: isBreathing ? 12 : 0)
                .scaleEffect(isBreathing ? 1.02 : 1.0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        isBreathing = true
                    }
                }
        }
    }
}

private struct PastPrimeRankBadge: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(tint.opacity(0.15))
            .foregroundStyle(tint)
            .clipShape(Capsule())
    }
}

private struct PastPrimeGameCard: View {
    let title: String
    let desc: String
    let latest: String
    let imageName: String
    let tint: Color
    let isFullWidth: Bool
    var customBackground: AnyView? = nil
    let onStart: () -> Void
    let onInfo: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            Button(action: onStart) {
                ZStack(alignment: .topLeading) {
                    if let bg = customBackground {
                        bg.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    } else {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(UIColor.secondarySystemBackground))
                    }
                    
                    GeometryReader { geo in
                        ZStack {
                            Image(imageName)
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(tint)
                                .frame(width: isFullWidth ? 90 : geo.size.width * 0.6)
                                .offset(x: isFullWidth ? geo.size.width - 100 : geo.size.width * 0.4, 
                                        y: isFullWidth ? 20 : geo.size.height * 0.4)
                                .opacity(0.8)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.system(size: isFullWidth ? 20 : 18, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                            
                        Text(desc)
                            .font(.system(size: isFullWidth ? 14 : 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.leading)
                            .padding(.bottom, 10)
                        
                        HStack(alignment: .top, spacing: 4) {
                            Image(systemName: latest.contains("未测试") ? "sun.max" : "checkmark")
                                .font(.caption.weight(.bold))
                                .offset(y: latest.contains("未测试") ? 0 : 2)
                            Text(latest)
                                .font(.caption.weight(.semibold))
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        .foregroundStyle(.white.opacity(0.8))
                        
                        Spacer(minLength: 0)
                    }
                    .padding(20)
                    .padding(.trailing, isFullWidth ? 40 : 0)
                }
                .frame(maxWidth: .infinity)
                .frame(height: isFullWidth ? 130 : 170)
            }
            .buttonStyle(.borderless)
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: onInfo) {
                        Image(systemName: "info.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding(16)
                            .offset(y: 4)
                    }
                    .buttonStyle(.borderless)
                }
                Spacer()
            }
        }
    }
}
