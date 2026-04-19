# Flow Bell

> macOS 菜单栏专注计时器，以随机提示音驱动微休息——让不规则的短暂中断保护专注状态，而非打断它。

![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey)
![Swift](https://img.shields.io/badge/swift-5.10-orange)
![License](https://img.shields.io/badge/license-MIT-blue)

---

## 设计理念

番茄工作法把工作切分为固定的 25 分钟块，用严格的时间边界强制休息。它是有效的——但固定节奏本身有时会成为干扰：你开始盯着倒计时，在"再多做一点"和"应该停下"之间反复权衡。

**Flow Bell** 采用了一种不同的思路，灵感来自正念微休息与可变比例强化的研究：

- 你选择一个更长的专注时段（默认 90 分钟），消除对固定终点的心理博弈。
- 专注期间，铃声会在**随机时间**响起（默认每 3–5 分钟一次）。响起时，你闭眼休息 10 秒——仅此而已。
- 随机性是关键。正因为你无法预测铃声何时到来，就无法对它产生期待。微休息来了，你休息，然后回到工作——专注的线索不会断开。
- 专注时段结束后进入真正的休息（默认 20 分钟），一个置顶浮窗倒计时接管屏幕。

最终形成的节奏不像节拍器，而更像自然的呼吸：持续的深度工作，穿插短暂而不可预期的放松。

---

## 功能

### 核心计时
- **专注阶段** — 可设置时长（15–180 分钟），菜单栏实时倒计时
- **休息阶段** — 置顶浮窗倒计时，始终显示在所有窗口之上；支持最小化、提前结束休息、直接开始下一轮专注
- 随时暂停 / 继续 / 重置；继续后距下一次铃声至少保留 30 秒缓冲

### 随机提示音（微休息）
- 铃声在设定区间内随机触发（如 3–5 分钟），触发时连续响两次以增强提醒效果
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

### 多语言支持
- 支持中文 / 英文界面切换
- 在「声音与行为」设置中选择语言

### 今日统计
- 主界面显示今日专注时长与完成轮次
- 数据按日重置，仅保留当天统计

---

## 安装

### 下载安装（推荐）
从 [最新发布页面](../../releases/latest) 下载 `Flow Bell.zip`，解压后将 `Flow Bell.app` 移入 `/Applications`。

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
| 提示音 | Glass | 所有系统内置音效（Glass、Hero、Submarine、Funk 等） |
| 语言 | 中文 | 中文 / 英文 |
| 主题色 | 经典蓝 | 经典蓝 / 鼠尾草 / 山脉蓝 / 薰衣草 / 玫瑰 / 钛金 / 星光 |
| 微休息结束提示音 | 开启 | — |
| 休息结束自动开始下一轮 | 关闭 | — |

内置预设：**Pomodoro 30/5**、**Focus 50/10**、**Flow 90/20**

---

## 技术栈

- **SwiftUI** + **AppKit** — 菜单栏 Extra、浮窗 NSPanel
- **Swift Package Manager** — 无需 Xcode 工程文件
- **UserNotifications** — 系统通知集成
- **NSSound** — 仅使用系统内置音效，无需额外音频资源
- **UserDefaults** — 设置与今日专注数据的轻量持久化

要求 macOS 13 Ventura 及以上。

---

## 项目结构

```
Sources/
  AppMain.swift                    程序入口，菜单栏图标渲染
  ContentView.swift                主面板 UI
  FocusEngine.swift                状态机、计时器、Ping 调度
  Preferences.swift                设置模型与持久化
  DailyStats.swift                 今日专注统计存储
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
