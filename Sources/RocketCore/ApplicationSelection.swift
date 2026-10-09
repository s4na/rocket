import Foundation

public enum ApplicationSelection {
  public static func filtered(
    _ applications: [RegisteredApplication], query: String
  ) -> [RegisteredApplication] {
    let search = query.trimmingCharacters(in: .whitespacesAndNewlines)
    return applications.filter {
      search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)
        || $0.bundleIdentifier.localizedCaseInsensitiveContains(search)
    }.sorted {
      let comparison = $0.name.localizedCaseInsensitiveCompare($1.name)
      return comparison == .orderedSame
        ? $0.bundleIdentifier < $1.bundleIdentifier : comparison == .orderedAscending
    }
  }

  public static func reconciled(
    _ selectedID: UUID?, in applications: [RegisteredApplication]
  ) -> UUID? {
    if let selectedID, applications.contains(where: { $0.id == selectedID }) {
      return selectedID
    }
    return applications.first?.id
  }

  public static func moved(
    _ selectedID: UUID?, by offset: Int, in applications: [RegisteredApplication]
  ) -> UUID? {
    guard !applications.isEmpty else { return nil }
    guard let index = applications.firstIndex(where: { $0.id == selectedID }) else {
      return applications.first?.id
    }
    let target = min(max(index + offset, 0), applications.count - 1)
    return applications[target].id
  }
}
