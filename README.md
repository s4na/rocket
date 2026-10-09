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

CI builds the app but does not validate interactive macOS behavior. Before distributing, check first launch, repeated shortcuts, Escape/Close, clicking another app, quitting/relaunching, a conflicting shortcut, full-screen Spaces, and multiple displays (including a Dock on another edge). See the window-shortcut guide for additional window-management checks.

## Register and launch applications

Use **Add Applications** to select `.app` bundles with the native picker. Search by name or bundle identifier, use Up/Down to select, and Return to launch; click an entry or use Open as well. Escape closes Rocket. The search field preserves Japanese IME composition (including Return to confirm text), and supports normal Cut/Copy/Paste/Select All shortcuts.

The local registry is stored at `~/Library/Application Support/Rocket/applications.json`. Entries keep a stable ID, bundle identifier, and a bookmark; relocated applications are resolved when possible. Missing apps remain listed so you can re-register or remove them. Removing a registry entry never deletes the app. A failed launch is shown in the launcher. Corrupt or newer-version storage is preserved with edits disabled; use Reload after repairing/restoring the file. No cloud sync, shell commands, or extra permissions are used.

Additional manual checks: register/cancel the picker repeatedly; search, arrows, Return and Escape with Japanese IME; paste into search; restart and verify persistence; move/delete a registered app; re-register it; remove only its entry; simulate a failed launch; verify corrupted storage is not overwritten. Picker sheets keep the host window open.

## Window shortcuts

For the focused window in another app, hold **Control–Option–Command** and press:

- Left/Right/Up/Down: corresponding half
- 1/2/3/4: top-left/top-right/bottom-left/bottom-right quarter (physical number keys)
- Return: maximize within the usable display area, not macOS full screen

Enable this optional feature with **Window Shortcuts → Enable Window Shortcuts** in Rocket's menu, then grant Accessibility access yourself in System Settings. Launcher usage does not request that permission. Failed operations show a nonactivating notice and preserve keyboard focus; the latest error also remains in the menu-bar icon's tooltip. Conflicting shortcuts are reported individually; other shortcuts remain registered. Change the conflicting shortcut in the other app and restart Rocket to retry.

See [window shortcuts](docs/window-shortcuts.md) for permissions, multiple displays, unsupported windows, minimum-size constraints, and manual checks.
