# Flow Bell

> A macOS menu bar focus timer with random bell cues — built on the idea that irregular interruptions preserve flow better than rigid time blocks.

![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey)
![Swift](https://img.shields.io/badge/swift-5.10-orange)
![License](https://img.shields.io/badge/license-MIT-blue)

---

## The Idea

The Pomodoro Technique works by dividing work into fixed 25-minute blocks, enforcing rest through strict time boundaries. It's effective — but the fixed rhythm can itself become a distraction: you start watching the clock, negotiating with yourself about whether to "finish this thought" before the timer rings.

**Flow Bell** takes a different approach, inspired by research on mindfulness micro-breaks and variable-ratio reinforcement:

- You commit to a longer focus block (default: 90 minutes), removing the temptation to coast toward a fixed endpoint.
- During the session, a bell rings at a **random interval** (default: every 3–5 minutes). When it rings, you close your eyes for 10 seconds — nothing more.
- The randomness is intentional. Because you can't predict when the bell will ring, you can't build anticipation for it. The micro-break arrives, you rest, and you return to work — without breaking the thread of concentration.
- At the end of the focus block, a proper rest begins (default: 20 minutes), with a floating countdown window that stays on top of all other apps.

The result is a rhythm that feels less like a metronome and more like natural breathing: sustained deep work, punctuated by brief, unpredictable moments of rest.

---

## Features

### Core Timer
- **Focus phase** — configurable duration (15–180 min), with a live countdown in the menu bar
- **Rest phase** — floating countdown window, always on top, with an option to skip early
- Pause / resume / reset at any time; resuming after pause adds a 30-second buffer before the next bell

### Random Bell (Micro-breaks)
- Bell rings at a random point within a configurable interval (e.g. 3–5 min)
- A floating notice appears with a countdown: "Close your eyes — 10 seconds"
- Optional end-cue sound when the micro-break finishes ("Back to focus")
- The next bell is only scheduled *after* the current micro-break ends — no stacking

### App Blocking
- Add apps to a block list; they are automatically hidden during focus sessions
- A brief notice appears when a blocked app is intercepted

### Menu Bar Display
Two modes:
- **Digital clock** — boxed countdown; shows configured focus duration when idle (e.g. `90:00`)
- **Progress ring** — arc fills as the session progresses

### Daily & Weekly Stats
- Today's focus minutes and completed sessions shown in the main panel
- "This week" view with a 7-day bar chart (accessible via settings)
- Data resets daily; history kept for 7 days

---

## Installation

### Download (recommended)
Download `Flow Bell.zip` from the [latest release](../../releases/latest), unzip, and move `Flow Bell.app` to `/Applications`.

> On first launch, macOS may show a security warning. Go to **System Settings → Privacy & Security** and click **Open Anyway**.

### Build from source
Requires Xcode Command Line Tools and Swift 5.10+.

```bash
git clone https://github.com/YoungFujun/flow-bell-mac.git
cd flow-bell-mac
./build_app.sh
```

The script compiles a release build, generates an app icon, and outputs:
- `dist/Flow Bell.app`
- `dist/Install Flow Bell.command` — double-click to install to `/Applications`
- `dist/Flow Bell.zip`

---

## Settings

| Setting | Default | Range |
|---|---|---|
| Focus duration | 90 min | 15–180 min |
| Rest duration | 20 min | 5–60 min |
| Bell interval (min) | 3 min | 1–15 min |
| Bell interval (max) | 5 min | 1–20 min |
| Micro-break length | 10 sec | 5–30 sec |
| Alert sound | Glass | Glass / Hero / Submarine / Funk |
| End-cue sound | On | — |
| Auto-start next session | Off | — |

Presets: **Flow 90/20**, **Pomodoro 25/5**, **Deep Work 52/17**

---

## Tech Stack

- **SwiftUI** + **AppKit** — menu bar extra, floating NSPanel windows
- **Swift Package Manager** — no Xcode project file required
- **UserNotifications** — system notification integration
- **NSSound** — system audio only, no bundled audio assets
- **UserDefaults** — lightweight persistence for settings and stats

macOS 13 Ventura or later required.

---

## Project Structure

```
Sources/
  AppMain.swift                    app entry, menu bar label rendering
  ContentView.swift                main panel UI
  FocusEngine.swift                state machine, timer, ping scheduling
  Preferences.swift                settings model + persistence
  DailyStats.swift                 daily/weekly stats store
  RestOverlayController.swift      floating rest countdown window
  BlockNoticeController.swift      app-blocked notice
  MicroBreakNoticeController.swift micro-break countdown notice
  InstalledAppsStore.swift         enumerates installed apps for block list
Resources/
  Info.plist
build_app.sh                       build + package script
```

---

## License

MIT
