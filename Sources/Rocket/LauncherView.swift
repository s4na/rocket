import SwiftUI

struct LauncherView: View {
  let onDismiss: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "paperplane.fill")
        .font(.system(size: 36))
        .accessibilityHidden(true)
      Text("Rocket").font(.largeTitle.bold())
      Text("A launcher app").foregroundStyle(.secondary)
      Text("Your launcher is ready.")
      Button("Close", action: onDismiss)
        .keyboardShortcut(.cancelAction)
    }
    .padding(32)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
