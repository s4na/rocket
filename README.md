# Rocket（ロケット）

ロケットという名前のランチャー、略して **ロケラン**。正式名は **Rocket（ロケット）** です。

A launcher app for macOS, written in Swift with AppKit and SwiftUI. Requires macOS 13 or later.

## Develop

Use Xcode 16 or later (Swift 6 toolchain; package uses Swift 5 language mode). No third-party dependencies or project generator are required.

```sh
swift test
swift format lint --strict --recursive Package.swift Sources Tests
bash scripts/build-app.sh
open .build/Rocket.app
```

## 使い方

1. 上の手順でアプリをビルドして起動します。メニューバーに紙飛行機のアイコンが表示されます。
2. `Control–Option–Space` を押すとランチャーが開きます。反応しない場合はメニューバーのアイコンから **Open Rocket** を選んでください。
3. **Add Applications…** から起動したい `.app` を登録し、検索欄に名前またはBundle IDを入力します。↑ / ↓ で選び、Return、**Open**、またはダブルクリックで起動します。
4. **Remove** はRocketの登録だけを削除し、アプリ本体は削除しません。Escapeまたは**Close**で閉じると、直前に使っていたアプリに戻ります。
5. Rocketを終了するには、メニューバーのアイコンから **Quit Rocket** を選びます。

ウィンドウ配置を使う場合は、メニューバーから **Window Shortcuts → Enable Window Shortcuts** を選び、システム設定でRocketにアクセシビリティを許可します。その後、配置したいアプリのウィンドウを前面にして次のキーを押します。

| 操作 | ショートカット（Control–Option–Command +） |
| --- | --- |
| 左 / 右 / 上 / 下半分 | ← / → / ↑ / ↓ |
| 左上 / 右上 / 左下 / 右下の四分割 | 1 / 2 / 3 / 4 |
| 最大化（メニューバーとDockを避ける） | Return |

最大化はmacOSのフルスクリーン表示にはなりません。フルスクリーン中のウィンドウや、移動・サイズ変更に対応しないウィンドウは配置できません。ショートカットが他のアプリと競合するときは起動時に通知されるので、そのアプリ側のキーを変更してRocketを再起動してください。

The launcher does not require Accessibility or Input Monitoring permission. The bundled development app is ad-hoc signed, not notarized or packaged for distribution. Build and open the `.app` rather than running the executable directly.

## CI and cost

Pull requests run one standard `macos-15` GitHub-hosted job for formatting lint, tests, and app-bundle compilation. Pushes only run on `main` to avoid duplicate push and PR builds. Superseded runs are cancelled; jobs time out after 10 minutes. No matrix, larger runner, cache, artifact upload, deployment, or release is configured.

[Standard GitHub-hosted runners are free for public repositories](https://docs.github.com/en/billing/concepts/product-billing/github-actions). The job explicitly skips private repositories rather than consuming paid minutes. If visibility changes, revisiting CI is a separate decision. No billing settings are changed.

## Manual checks

CI builds the app but does not validate interactive macOS behavior. Before distributing, check first launch, repeated shortcuts, Escape/Close, clicking another app, quitting/relaunching, a conflicting shortcut, full-screen Spaces, and multiple displays (including a Dock on another edge). See the window-shortcut guide for additional window-management checks.

## Register and launch applications

Use **Add Applications** to select `.app` bundles with the native picker. Search by name or bundle identifier, use Up/Down to select, and Return to launch; double-click an entry or use Open as well. Escape closes Rocket. The search field preserves Japanese IME composition (including Return to confirm text), and supports normal Cut/Copy/Paste/Select All shortcuts.

The local registry is stored at `~/Library/Application Support/Rocket/applications.json`. Entries keep a stable ID, bundle identifier, and a bookmark; relocated applications are resolved when possible. Missing apps remain listed so you can re-register or remove them. Removing a registry entry never deletes the app. A failed launch is shown in the launcher. Corrupt or newer-version storage is preserved with edits disabled; use Reload after repairing/restoring the file. No cloud sync, shell commands, or extra permissions are used.

Additional manual checks: register/cancel the picker repeatedly; search, arrows, Return and Escape with Japanese IME; paste into search; restart and verify persistence; move/delete a registered app; re-register it; remove only its entry; simulate a failed launch; verify corrupted storage is not overwritten. Picker sheets keep the host window open.

With the picker open, switch to another app, then use the global shortcut or menu-bar entry to restore the same picker. For a slow launch, dismiss and reopen Rocket before completion: the old request should not activate its target or close the new launcher. The requested app can still finish launching in the background; Rocket does not terminate it. Also open the picker while a launch is pending and verify its completion does not interrupt the sheet.

## Window shortcuts

The shortcut map and setup steps are listed in [使い方](#使い方). Launcher usage does not request Accessibility access. Failed window operations show a nonactivating notice and preserve keyboard focus; the latest error also remains in the menu-bar icon's tooltip. Conflicting shortcuts are reported individually; other shortcuts remain registered.

See [window shortcuts](docs/window-shortcuts.md) for permissions, multiple displays, unsupported windows, minimum-size constraints, and manual checks.
