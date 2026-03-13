# 反应速度测试（Reaction Time Test）小游戏 - 技术文档（iOS）

版本：v1.0  
作者：—  
更新时间：2026-03-12  
技术栈建议：Swift 5.9+，SwiftUI（iOS 16+）

---

## 1. 技术目标
- **准确测量**“绿屏出现”到“用户点击”的时间差（ms）
- **稳定体验**：状态可控、可取消、可恢复（后台/来电/通知）
- **可扩展**：支持历史记录、分享卡片、埋点与后续多人/排行榜

## 2. 总体架构（建议）
采用“UI（SwiftUI） + 业务引擎（GameEngine） + 存储（Repository）”分层：

- `ReactionTestView`：全屏交互与展示
- `ReactionTestViewModel`（`@MainActor` / `ObservableObject`）：状态驱动 UI
- `GameEngine`：控制状态机、随机延迟、时间戳记录
- `SessionRepository`：本地持久化（UserDefaults/文件 JSON/SwiftData）
- `Analytics`：埋点接口（可空实现）

> v1 建议优先保证状态机正确与体验一致；若要追求更高测量精度，可在后续切换到 UIKit 方案（见第 9 节）。

## 3. 数据模型
### 3.1 单次结果
```swift
enum TrialOutcome: String, Codable {
  case success
  case falseStart
  case timeout
  case cancelled
}

struct TrialResult: Codable, Identifiable {
  let id: UUID
  let index: Int                 // 第几次（1...N）
  let outcome: TrialOutcome
  let reactionMs: Int?           // 仅 success 有值
  let waitDelayMs: Int?          // 红到绿的随机延迟（用于调试/分析）
  let timestamp: Date
}
```

### 3.2 一轮会话
```swift
struct SessionResult: Codable, Identifiable {
  let id: UUID
  let trialCount: Int
  let trials: [TrialResult]
  let averageMs: Int?            // success 的平均
  let bestMs: Int?
  let falseStartCount: Int
  let createdAt: Date
}
```

## 4. 状态机设计
### 4.1 状态枚举
```swift
enum GamePhase: Equatable {
  case idle
  case waitingForGreen(trialIndex: Int, endsAtUptimeNs: UInt64)
  case green(trialIndex: Int, greenAtUptimeNs: UInt64)
  case showingTrialResult(trialIndex: Int, resultMs: Int)
  case falseStart(trialIndex: Int)
  case finished(session: SessionResult)
}
```

### 4.2 状态流转（核心）
- `idle` → 用户点击开始 → `waitingForGreen`
- `waitingForGreen`：
  - 到达随机延迟 → 进入 `green`
  - 用户点击 → `falseStart`（本次不计入 success）
- `green`：
  - 用户点击 → 计算 `reactionMs` → `showingTrialResult`
  - 超时（可选，如 3s）→ 记录 timeout → `showingTrialResult/下一次`
- `showingTrialResult` → 用户点击继续 → 下一次 `waitingForGreen`，或最后一次 → `finished`
- `falseStart` → 展示提示 → 用户点击重试 → 同一 `trialIndex` 重新进入 `waitingForGreen`

## 5. 计时与精度
### 5.1 为什么不用 `Date()`
`Date()` 受系统时间调整影响（时区/校时），不适合高精度间隔测量。

### 5.2 推荐时间源
- `DispatchTime.now().uptimeNanoseconds`（单调递增，适合测间隔）

计算：
```swift
let reactionMs = Int((tapUptimeNs - greenUptimeNs) / 1_000_000)
```

### 5.3 “绿屏出现”时间点的定义
v1（SwiftUI）建议将 `greenAtUptimeNs` 记录在**状态切换为 green 的同一时刻**。这会把一部分“渲染到屏幕”的延迟计入反应时间，但在同一设备上通常相对稳定，适合娱乐与对比。

若需要更贴近“屏幕真实显示时刻”，可在后续用 `CADisplayLink` 或 UIKit 直接刷新背景并在下一帧回调记录（见第 9 节）。

## 6. 随机延迟实现（可取消）
Swift Concurrency 方式（推荐，易取消）：

- 在进入 `waitingForGreen` 时创建 `Task`
- 使用 `Task.sleep(nanoseconds:)` 等待随机时长
- 若用户误触、离开页面或开始下一轮，取消旧任务避免串状态

范围建议：
- `delay = Double.random(in: 1.5...4.5)` 秒

## 7. 交互与输入处理
### 7.1 点击区域
- 全屏可点击（避免按钮太小）
- 支持 `onTapGesture`（触屏）
- 可选：外接键盘 `Space/Enter` 触发（提升可玩性）

### 7.2 防连点
- 在 `showingTrialResult` 设置最短停留（如 250ms）或只接受“抬手后下一次点击”
- iOS 手势层可通过简单节流实现（记录上次点击时间）

### 7.3 后台与中断
- App 进入后台：取消当前 `Task`，标记 trial 为 `cancelled` 或直接回到 `idle`
- 电话/通知导致中断：同上

## 8. 结果计算与展示
### 8.1 平均值规则
- 仅对 `success` 的 `reactionMs` 取平均
- 若 success 数为 0：不输出平均，提示“本轮无有效成绩”

### 8.2 年龄参考提示（仅产品文案）
按 PRD 文案展示参考区间：
- 平均 `< 220ms` ≈ 20–30 岁
- `250–300ms` ≈ 40 岁
- `> 350ms` ≈ 60+ 岁

技术上建议：
- 文案层展示“参考”而非“判定”
- 不在本地生成“医学结论”字段，避免后续合规风险

## 9. SwiftUI vs UIKit（精度权衡）
### 9.1 SwiftUI（推荐 v1）
优点：开发快、状态驱动清晰、适合 MVP  
缺点：UI 渲染时机更“黑盒”，绿屏实际显示与状态切换存在小延迟

### 9.2 UIKit（追求更高一致性）
思路：
- `UIViewController` 全屏 `UIView` 直接切背景色
- 使用 `touchesBegan(_:with:)` 获取触摸
- 绿屏切换后通过 `CADisplayLink` 在下一帧记录“显示时刻”（近似）

结论：若产品要强调“专业测量”，建议切 UIKit；若是“小游戏/自测”，SwiftUI 足够。

## 10. 本地存储方案
v1 推荐 `UserDefaults + JSON`（简单可靠）：
- 保存最近 `N=30` 条 `SessionResult`
- 超出删除最旧

扩展：
- 若需要查询/筛选/趋势图：引入 SwiftData/CoreData

## 11. 埋点（可选）
建议事件：
- `reaction_test_start`（trialCount）
- `reaction_trial_false_start`（trialIndex）
- `reaction_trial_success`（trialIndex, reactionMs）
- `reaction_test_finish`（averageMs, bestMs, falseStartCount）
- `share_result`（channel）

注意：
- 默认不采集可识别个人信息
- 若接入第三方分析 SDK，补充隐私条款与弹窗授权流程

## 12. 测试与验收（技术侧）
### 12.1 单元测试（XCTest）
- 平均值计算：空数组/含 falseStart/含 timeout
- 随机延迟范围：保证上下界
- 状态机：falseStart 不推进 trialIndex；success 正常推进

### 12.2 手工测试清单
- 连续快速点击：不会跳过 trial 或产生负数 ms
- 旋转屏幕（若锁竖屏则忽略）
- 后台再回前台：不会卡在 waiting 状态
- 开关声音/震动：立即生效

## 13. 代码组织建议（示例）
- `Features/ReactionTest/ReactionTestView.swift`
- `Features/ReactionTest/ReactionTestViewModel.swift`
- `Features/ReactionTest/GameEngine.swift`
- `Data/SessionRepository.swift`
- `Data/Models.swift`
- `Services/Analytics.swift`

## 14. 震动与音效（可配置）
### 14.1 震动（Haptics）
- 绿屏出现：`UIImpactFeedbackGenerator(style: .light)`
- 过早点击：`UINotificationFeedbackGenerator().notificationOccurred(.error)`
- 点击成功：`UIImpactFeedbackGenerator(style: .rigid)`（或 `.light`）

实现建议：
- 生成器在进入页面时创建并 `prepare()`，减少延迟
- 遵从设置开关；关闭时不触发

### 14.2 音效（Sound）
v1 建议使用简单短音：
- 方案 A：`AudioServicesPlaySystemSound`（低成本，但可控性弱）
- 方案 B：`AVAudioPlayer`（可调音量/静音/资源管理更好）

注意：
- iOS 静音键策略：是否遵从静音取决于产品定位；建议遵从系统静音（避免打扰）

## 15. 分享结果卡片（可选）
### 15.1 SwiftUI 渲染为图片
iOS 16+ 可用 `ImageRenderer`：
- 用一个专用 `ResultCardView`（纯 SwiftUI）渲染为 `UIImage`
- 通过 `ShareLink` 或 UIKit `UIActivityViewController` 分享

### 15.2 分享内容建议
- 平均 ms、最佳 ms、试次数、日期
- 文案避免“年龄判定”，仅放“参考区间/免责声明”（如 PRD 7.6）

## 16. 无障碍（Accessibility）
- 语义：状态文本用 `accessibilityLabel` 明确读出（如“等待”“现在点击”）
- 触发：可选支持外接键盘 Space/Enter
- 色弱：UI 必须包含文字/图标，不依赖红绿

## 17. 已知限制与校准建议
- 不同设备/系统版本的触控采样、显示刷新率会影响绝对值；建议主打“同设备趋势对比”
- SwiftUI 方案记录的是“状态切换时刻”，会包含少量渲染延迟；如需更高一致性可切 UIKit（第 9 节）

