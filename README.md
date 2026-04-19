# Flow Bell

> macOS 菜单栏专注计时器，以随机提示音驱动微休息——让不规则的短暂中断保护专注状态，而非打断它。

![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey)
![Swift](https://img.shields.io/badge/swift-5.10-orange)
![License](https://img.shields.io/badge/license-MIT-blue)

[English](#english)

---

## 设计理念

### 固定节奏的隐性问题

番茄工作法把工作切分为固定的时间块，是很多人的入门选择。它是有效的——问题不在于 25 分钟，而在于**固定节奏本身**：当你知道铃声会在某个时间响起，大脑就会提前"收工"。在最后几分钟，注意力已经开始松弛；铃声一响，又要花时间重新进入状态。节奏越固定，这种心理摩擦越明显——无论你把时间块设成 25 分钟还是 52 分钟。

### 为什么随机性有效

当你知道铃声会在某个固定时间响起，你会不自觉地倒计时等它。但如果你完全不知道它什么时候来，你就没法等——只能继续工作。

这不是直觉，行为心理学研究早已证实：**不可预测的提示比固定提示更能维持持续的注意力**，因为大脑无法提前对它建立期待和应对。Flow Bell 把这个原理用在休息上：铃声随机，所以它不会被期待，不会提前打断你的思路。

### 为什么是 10 秒闭眼

长时间专注会持续消耗大脑的认知资源，神经科学研究发现，哪怕极短暂的「脱离」——闭眼、停止信息输入——就能让大脑的休息网络短暂激活，延缓疲劳累积的速度。10 秒不足以让你失去工作状态，却足以给眼睛和注意力一次微小的重置。

### 整体节奏

- **长时段专注**（默认 90 分钟）：不设中间终点，让心流真正建立起来
- **随机铃声**：不可预期，因此不被期待，不打断专注
- **10 秒闭眼**：最小代价的微恢复
- **20 分钟真正休息**：专注结束后，置顶浮窗强制离开屏幕，完成深度恢复

最终形成的节奏不像节拍器，而更像自然的呼吸。

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

## 许可证

MIT

---

## English

> A macOS menu bar focus timer with random bell cues — built on the idea that irregular interruptions preserve flow better than rigid time blocks.

### The Idea

Fixed time blocks — whether 25 minutes or 52 — are a popular way to structure work. They're effective. But the fixed rhythm creates a subtle problem: **you start anticipating the break**. In the final minutes, your brain is already winding down; when the bell rings, you need time to rebuild momentum. The issue isn't the length of the block — it's the predictability.

Flow Bell works differently. Because the bell arrives at a random interval, you can't countdown to it — there's nothing to wait for. Behavioral psychology has long shown that unpredictable cues sustain attention better than fixed ones: the brain stays engaged precisely because it can't predict what comes next.

When the bell rings, you close your eyes for 10 seconds. That's it. Brief enough that you don't lose your train of thought; enough to give your visual system and attention a small reset before continuing.

At the end of the session, a 20-minute rest begins — a floating window that stays on top of everything, so you actually step away from the screen.

The result feels less like a metronome and more like natural breathing.

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
