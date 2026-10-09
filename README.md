# Rocket

A launcher app for macOS, written in Swift with AppKit and SwiftUI. Requires macOS 13 or later.

## Develop

Use Xcode 16 or later (Swift 6 toolchain; package uses Swift 5 language mode). No third-party dependencies or project generator are required.

```sh
swift test
swift format lint --strict --recursive Package.swift Sources Tests
bash scripts/build-app.sh
open .build/Rocket.app
```

Control–Option–Space opens a single launcher window on the pointer's display. Repeating the shortcut focuses the same window. Escape or Close dismisses it and restores the previous app; choosing another app dismisses Rocket without stealing focus. The menu-bar icon can open Rocket or quit it. If another app owns the shortcut, Rocket reports the conflict and the menu-bar entry remains available. Change that app's shortcut and restart Rocket to retry.

The launcher does not require Accessibility or Input Monitoring permission. The bundled development app is ad-hoc signed, not notarized or packaged for distribution. Build and open the `.app` rather than running the executable directly.

## CI and cost

Pull requests run one standard `macos-15` GitHub-hosted job for formatting lint, tests, and app-bundle compilation. Pushes only run on `main` to avoid duplicate push and PR builds. Superseded runs are cancelled; jobs time out after 10 minutes. No matrix, larger runner, cache, artifact upload, deployment, or release is configured.

[Standard GitHub-hosted runners are free for public repositories](https://docs.github.com/en/billing/concepts/product-billing/github-actions). The job explicitly skips private repositories rather than consuming paid minutes. If visibility changes, revisiting CI is a separate decision. No billing settings are changed.

## Manual checks

CI builds the app but does not validate interactive macOS behavior. Before distributing, check first launch, repeated shortcuts, Escape/Close, clicking another app, quitting/relaunching, a conflicting shortcut, full-screen Spaces, and multiple displays (including a Dock on another edge). App registration and window actions will be added in the next chained changes.
