# Flow Bell

> macOS 菜单栏专注计时器，以随机提示音驱动微休息——让不规则的短暂中断保护专注状态，而非打断它。

![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey)
![Swift](https://img.shields.io/badge/swift-5.10-orange)
![License](https://img.shields.io/badge/license-MIT-blue)

[English](#english)

---

## 设计理念

### 番茄工作法的局限

番茄工作法把工作切分为固定的 25 分钟块。它是有效的——但固定节奏本身会带来一个隐性问题：**你开始预期休息的到来**。在最后几分钟里，大脑已经开始"收工"，专注度悄悄下滑；而铃声一响，你又要花时间重新进入状态。节奏越固定，这种心理摩擦就越明显。

### 随机性如何解决这个问题

行为心理学长期研究表明，**可变比例强化程序**（variable-ratio schedule）产生的行为最为持久、最难消退——赌博机正是利用了这一原理。当奖励或提示的时机不可预测时，大脑无法提前"锁定"它，只能保持持续的警觉状态（Ferster & Skinner, *Schedules of Reinforcement*, 1957）。

Flow Bell 把这个原理反过来用：**不是用随机性制造期待，而是用随机性消除期待**。因为你不知道铃声什么时候响，你就无法在心里倒计时等它——只能专注于手头的工作。

### 微休息与默认模式网络

持续专注会消耗前额叶皮质的认知资源，同时抑制大脑的**默认模式网络**（Default Mode Network，DMN）——这是与自我整合、记忆巩固和创造性思维相关的核心网络。神经影像研究显示，DMN 活跃度越高，个体对长时间注意力任务的抵抗力越强；而长时间不间断工作会显著损害 DMN 功能（Gui et al., *PLOS ONE*, 2015）。

短暂的脱离（哪怕 10 秒的闭眼）能让 DMN 短暂激活，延缓认知疲劳的积累。2022 年一项纳入 22 项研究、共 2335 名被试的元分析证实，微休息能可靠地降低疲劳感、提升活力（Albulescu et al., *PLOS ONE*, 2022）。

### Flow Bell 的设计逻辑

- **长时段专注**（默认 90 分钟）：消除对固定终点的心理博弈，让你真正进入心流状态。
- **随机铃声**（默认每 3–5 分钟一次）：不可预测，因此不会被期待，不会打断专注的线索。
- **10 秒闭眼**：足够让视觉系统和 DMN 获得短暂恢复，不足以让你失去工作状态。
- **20 分钟真正休息**：专注时段结束后，置顶浮窗强制与屏幕脱离，完成深度恢复。

最终形成的节奏不像节拍器，而更像自然的呼吸：持续的深度工作，穿插短暂而不可预期的放松。

---

## 功能

### 核心计时
- **专注阶段** — 可设置时长（15–180 分钟），菜单栏实时倒计时
- **休息阶段** — 置顶浮窗倒计时，始终显示在所有窗口之上，支持提前结束
- 随时暂停 / 继续 / 重置；继续后距下一次铃声至少保留 30 秒缓冲

### 随机提示音（微休息）
- 铃声在设定区间内随机触发（如 3–5 分钟）
- 浮窗弹出倒计时提示：「闭眼微休息 — 10 秒」
- 可选微休息结束提示音（「回到专注」）
- 下一次铃声仅在当前微休息结束后才开始安排，不会重叠触发

### App 专注拦截
- 设置禁用 App 列表，专注期间被打开的应用自动隐藏
- 被拦截时弹出简短提示通知

### 菜单栏显示
两种模式可选：
- **数字时钟** — 带边框的倒计时；空闲时显示设定的专注时长（如 `90:00`）
- **圆环盈缺** — 弧形进度随专注推进逐渐填满

### 每日与每周统计
- 主界面显示今日专注时长与完成轮次
- 设置页内置「本周统计」入口，7 天柱状图展示历史数据
- 数据按日重置，保留最近 7 天历史

---

## 安装

### 下载安装（推荐）
从 [最新发布页面](../../releases/latest) 下载 `Flow.Bell.zip`，解压后将 `Flow Bell.app` 移入 `/Applications`。

> 首次启动时 macOS 可能显示安全警告，前往 **系统设置 → 隐私与安全性**，点击「仍要打开」。

### 从源码构建
需要 Xcode Command Line Tools 和 Swift 5.10+。

```bash
git clone https://github.com/YoungFujun/flow-bell-mac.git
cd flow-bell-mac
./build_app.sh
```

脚本将编译 release 版本、生成图标，并输出：
- `dist/Flow Bell.app`
- `dist/Install Flow Bell.command` — 双击即可安装到 `/Applications`
- `dist/Flow Bell.zip`

---

## 设置项

| 设置 | 默认值 | 范围 |
|---|---|---|
| 专注时长 | 90 分钟 | 15–180 分钟 |
| 休息时长 | 20 分钟 | 5–60 分钟 |
| 随机铃声最短间隔 | 3 分钟 | 1–15 分钟 |
| 随机铃声最长间隔 | 5 分钟 | 1–20 分钟 |
| 微休息时长 | 10 秒 | 5–30 秒 |
| 提示音 | Glass | Glass / Hero / Submarine / Funk |
| 微休息结束提示音 | 开启 | — |
| 休息结束自动开始下一轮 | 关闭 | — |

内置预设：**Flow 90/20**、**Pomodoro 25/5**、**Deep Work 52/17**

---

## 技术栈

- **SwiftUI** + **AppKit** — 菜单栏 Extra、浮窗 NSPanel
- **Swift Package Manager** — 无需 Xcode 工程文件
- **UserNotifications** — 系统通知集成
- **NSSound** — 仅使用系统内置音效，无需额外音频资源
- **UserDefaults** — 设置与统计数据的轻量持久化

要求 macOS 13 Ventura 及以上。

---

## 项目结构

```
Sources/
  AppMain.swift                    程序入口，菜单栏图标渲染
  ContentView.swift                主面板 UI
  FocusEngine.swift                状态机、计时器、Ping 调度
  Preferences.swift                设置模型与持久化
  DailyStats.swift                 每日/每周统计存储
  RestOverlayController.swift      休息置顶浮窗
  BlockNoticeController.swift      App 拦截通知
  MicroBreakNoticeController.swift 微休息倒计时通知
  InstalledAppsStore.swift         已安装 App 枚举（用于拦截列表）
Resources/
  Info.plist
build_app.sh                       构建与打包脚本
```

---

## 参考文献

- Ferster, C. B., & Skinner, B. F. (1957). *Schedules of Reinforcement*. Appleton-Century-Crofts.
- Gui, W., et al. (2015). [Default mode network and its role in mental fatigue](https://pmc.ncbi.nlm.nih.gov/articles/PMC4589485/). *PLOS ONE*.
- Albulescu, P., et al. (2022). [Give your ideas some legs: The positive effect of walking on creative thinking](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0272460). *PLOS ONE* (meta-analysis, N=2335).

---

## 许可证

MIT

---

## English

> A macOS menu bar focus timer with random bell cues — built on the idea that irregular interruptions preserve flow better than rigid time blocks.

### The Science

**Variable-ratio schedules keep the brain alert.** Behavioral psychology has long established that unpredictable cues produce the most sustained attention — because the brain cannot anticipate them, it stays engaged rather than coasting toward a predicted event (Ferster & Skinner, 1957). Flow Bell applies this principle in reverse: randomness eliminates the countdown effect, not creates it.

**Micro-breaks restore the Default Mode Network.** Sustained focus suppresses the brain's Default Mode Network (DMN) — the system linked to memory consolidation, self-regulation, and creative thinking. Research shows high resting DMN activity predicts better resistance to mental fatigue; prolonged uninterrupted work significantly impairs it (Gui et al., 2015). Even 10 seconds of disengagement allows partial DMN reactivation. A 2022 meta-analysis of 22 studies (N=2,335) confirmed that micro-breaks reliably reduce fatigue and increase vigor (Albulescu et al., 2022).

**Longer blocks, less context-switching.** The default 90-minute session removes the temptation to coast toward a fixed endpoint. You don't watch the clock — because the clock gives no useful information about when the next bell will arrive.

### Features

- Configurable focus / rest durations with three built-in presets (Flow 90/20, Pomodoro 25/5, Deep Work 52/17)
- Random bell micro-breaks with floating countdown notice
- App blocking during focus sessions
- Dual menu bar display: digital clock or progress ring
- 7-day bar chart stats

### Build from source

```bash
git clone https://github.com/YoungFujun/flow-bell-mac.git
cd flow-bell-mac
./build_app.sh
```

Requires Xcode Command Line Tools and Swift 5.10+. macOS 13 Ventura or later.
