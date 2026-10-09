import AppKit
import RocketCore
import SwiftUI

@MainActor
struct LauncherView: View {
  @ObservedObject var registry: ApplicationRegistry
  var onLaunch: (RegisteredApplication) -> Void
  var onDismiss: () -> Void

  @State private var query = ""
  @State private var selectedID: UUID?

  private var filteredApplications: [RegisteredApplication] {
    ApplicationSelection.filtered(registry.applications, query: query)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Rocket").font(.title2.bold())
        Spacer()
        Button("Add Applications…", action: registry.addApplications)
          .disabled(!registry.canEdit)
        Button("Close", action: onDismiss).keyboardShortcut(.cancelAction)
      }
      LauncherSearchField(
        text: $query, onMove: moveSelection, onSubmit: launchSelected, onCancel: onDismiss
      )
      .frame(height: 28)
      applicationList
      if let message = registry.errorMessage {
        HStack(alignment: .top) {
          Text(message).font(.callout).foregroundStyle(.red).textSelection(.enabled)
          Spacer()
          Button("Reload", action: registry.refresh)
        }
      }
      HStack {
        Button("Remove") {
          if let selectedID { registry.remove(selectedID) }
        }
        .disabled(selectedID == nil || !registry.canEdit)
        Text("↑ ↓ to select · Return to open").font(.caption).foregroundStyle(.secondary)
        Spacer()
        Button("Open", action: launchSelected)
          .keyboardShortcut(.defaultAction)
          .disabled(selectedID == nil || registry.isLaunching)
      }
    }
    .padding(20)
    .frame(minWidth: 520, minHeight: 340)
    .onAppear(perform: reconcileSelection)
    .onChange(of: query) { _ in reconcileSelection() }
    .onChange(of: registry.applications) { _ in reconcileSelection() }
  }

  private var applicationList: some View {
    ScrollViewReader { proxy in
      List(selection: $selectedID) {
        ForEach(filteredApplications) { application in
          HStack(spacing: 10) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: application.path))
              .resizable().frame(width: 28, height: 28)
              .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
              Text(application.name)
              Text(
                registry.missingIDs.contains(application.id)
                  ? "Application unavailable. Add it again to update its location."
                  : application.bundleIdentifier
              )
              .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
          }
          .padding(.vertical, 3)
          .tag(application.id)
          .contentShape(Rectangle())
          .onTapGesture(count: 2) {
            selectedID = application.id
            launchSelected()
          }
        }
      }
      .listStyle(.inset)
      .overlay {
        if filteredApplications.isEmpty {
          Text(
            registry.applications.isEmpty
              ? "Add applications to get started."
              : "No matching applications."
          )
          .foregroundStyle(.secondary)
          .allowsHitTesting(false)
        }
      }
      .onChange(of: selectedID) { id in
        if let id { proxy.scrollTo(id) }
      }
    }
  }

  private func reconcileSelection() {
    selectedID = ApplicationSelection.reconciled(selectedID, in: filteredApplications)
  }

  private func moveSelection(_ offset: Int) {
    selectedID = ApplicationSelection.moved(selectedID, by: offset, in: filteredApplications)
  }

  private func launchSelected() {
    guard let application = filteredApplications.first(where: { $0.id == selectedID }) else {
      return
    }
    onLaunch(application)
  }
}
