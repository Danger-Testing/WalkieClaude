# WalkieClaude - Agent Instructions

## Project: WalkieClaude - macOS Walkie-Talkie AI Desktop App

## Build & Run
- **Build**: `swift build` from project root
- **Run**: `swift run` or ⌘R in Xcode (open Package.swift)

## Architecture
- **Framework**: SwiftUI + AppKit (NSPanel), Swift Package Manager executable
- **Target**: macOS 14+
- **Speech**: Apple Speech framework (STT) + AVSpeechSynthesizer (TTS)
- **API**: Anthropic Messages API (streaming SSE)
- **CLI**: Shells out to `claude -p` for CODE mode

## Key Files
- `WalkieClaudeApp.swift` — App entry, NSPanel window setup, global hotkey (Cmd+Shift+W)
- `WalkieTalkieView.swift` — Main UI (retro walkie-talkie aesthetic)
- `WalkieViewModel.swift` — State management, mode switching, API orchestration
- `AnthropicService.swift` — Streaming Claude API calls
- `CLIService.swift` — claude CLI subprocess bridge
- `SpeechService.swift` — Push-to-talk STT + TTS
- `KeychainService.swift` — Secure key storage

## TODOs / Notes
- **Floating panel**: Currently disabled (`isFloatingPanel = false`, `level = .normal`). Eventually re-enable as a user preference/toggle.
- API key is hardcoded in `WalkieViewModel.swift` as `defaultAPIKey`. Migrate to proper Keychain or env var setup later.

## Code Standards
- Use Swift concurrency (async/await, @MainActor)
- Keep responses streaming for real-time feel
- Retro radio aesthetic: dark grays, orange/amber accents
