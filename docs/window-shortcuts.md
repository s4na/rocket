# Window shortcuts

Rocket is a macOS launcher. Its window shortcuts move and resize the focused
window of another app into halves, corner quarters, or the display's usable area.
Maximize preserves the menu bar and Dock; it does not enter macOS full screen.

## Accessibility setup

Opening Rocket and using the launcher do not request Accessibility access.
Choose **Enable Window Shortcuts** in Rocket's menu only when you want this
feature. macOS may ask you to enable Rocket in **System Settings → Privacy &
Security → Accessibility**. Permission is granted there by you, not by Rocket.
The prompt returns before this choice is complete. After granting access, focus
another app and retry a window shortcut. Relaunch Rocket if macOS requires it.

If permission is missing or later revoked, the shortcut reports that setup is
needed. It does not repeatedly open permission prompts. Screen Recording,
Automation, and Input Monitoring permissions are not required by this feature.
When developing an unsigned or ad-hoc-signed build, replacing/moving the app may
require authorizing that build again; use the packaged Rocket app for testing.

## Behavior and limits

- The target is captured at the instant the shortcut is handled. Opening the
  launcher earlier does not determine which app gets moved.
- A window spanning displays uses the display with its largest intersection.
  Ties favor the display containing its center. An off-screen window uses the
  closest display.
- Layout uses logical points and each display's current usable frame, including
  displays to the left, above, or below the primary display.
- Full-screen windows, windows without move/resize support, and apps with no
  focused window are rejected with feedback. Exit full screen first.
- Some apps enforce a minimum size or their own layout. Rocket verifies the
  resulting frame, attempts to restore the previous frame on rejection, and
  reports whether restoration succeeded. It does not promise every app can fit
  into a quarter of every display.
- Moving is asynchronous and bounded by Accessibility messaging timeouts.
  Overlapping shortcuts receive a “move in progress” message rather than building
  an unbounded queue. The app is not activated just to move its window.

## Manual verification on macOS

Use ordinary disposable windows. These checks require a real graphical macOS
session and intentionally do not run in CI or grant permissions automatically.

1. With Rocket absent from Accessibility permissions, start it and invoke the
   launcher. Neither action should show a permission prompt.
2. Invoke a window shortcut: verify a helpful missing-permission message, with no
   system prompt. Check the notice is visible while Rocket stays inactive and
   does not intercept clicks. Explicitly choose Enable Window Shortcuts and verify setup is
   initiated. Decline, retry, then grant access and retry.
3. In TextEdit and Terminal, test left/right and top/bottom halves, all four
   corners, and maximize. Check the Dock and menu bar remain unobstructed.
4. Focus app A, open/dismiss Rocket, then focus app B and use a window shortcut.
   Only app B should move. When Rocket itself is focused, reject the operation.
5. Test displays positioned left, right, above, and below the primary display,
   with different sizes/scaling. Test a straddling window and move the Dock to a
   side. Compare the target with that display's usable frame.
6. Close every window in an app, use a nonresizable utility window, and enter
   native full screen. Verify each unsupported case has clear feedback and no
   unintended fullscreen transition or app activation.
7. Test an app with a large minimum window size on a small display. Verify a
   rejected quarter placement reports its constraint and restores the prior
   frame where possible.
8. Revoke Accessibility access while Rocket is running and retry. Disconnect a
   display with a window on it, then retry. Verify failure/recovery is clear.
9. Repeat shortcuts rapidly and test an unresponsive disposable app. Rocket's UI
   should remain usable; requests should not accumulate indefinitely.

## Developer integration

Keep one `WindowTilingController` instance on the main actor. Register global
hotkeys without activating Rocket and call:

```swift
tilingController.tileFrontmostWindow(.leftHalf) { result in
    if case let .failure(error) = result {
        // Show this to the user via the app's existing feedback UI.
        showError(error.localizedDescription)
    }
}
```

Call `requestAccessibilityPermission()` only from the explicit Enable Window
Shortcuts action. `accessibilityStatus` is a non-prompting check; inspect it afresh
rather than caching a grant. All completions run on the main thread. The focused
window lookup has a short messaging timeout; frame changes and verification run
on a serial background queue. Do not call the tiling controller from a launcher
activation path and do not request access at startup.

`WindowGeometryTests` exercise placement, screen selection, primary-display
coordinate conversion, odd dimensions, and readback tolerance without querying
Accessibility or changing real windows.

Apple references: [NSScreen.screens](https://developer.apple.com/documentation/appkit/nsscreen/screens)
(primary display ordering),
[AXIsProcessTrustedWithOptions](https://developer.apple.com/documentation/applicationservices/1459186-axisprocesstrustedwithoptions)
(explicit permission prompt), and
[kAXPositionAttribute](https://developer.apple.com/documentation/applicationservices/kaxpositionattribute).
