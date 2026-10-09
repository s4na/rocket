import Carbon
import Foundation

/// Carbon registers only these key combinations; no keyboard monitoring permission is needed.
final class GlobalShortcuts {
  private var handler: EventHandlerRef?
  private var registrations: [EventHotKeyRef] = []
  private var actions: [UInt32: () -> Void] = [:]
  private var nextID: UInt32 = 1
  private let signature: OSType = 0x524F_434B  // ROCK

  init() throws {
    var eventType = EventTypeSpec(
      eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)
    )
    let result = InstallEventHandler(
      GetApplicationEventTarget(),
      { _, event, context in
        guard let event, let context else { return OSStatus(eventNotHandledErr) }
        var hotKey = EventHotKeyID()
        let status = GetEventParameter(
          event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
          nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKey
        )
        guard status == noErr else { return status }
        let owner = Unmanaged<GlobalShortcuts>.fromOpaque(context).takeUnretainedValue()
        guard hotKey.signature == owner.signature, let action = owner.actions[hotKey.id] else {
          return OSStatus(eventNotHandledErr)
        }
        action()
        return noErr
      },
      1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &handler
    )
    guard result == noErr else { throw ShortcutError.registration(result) }
  }

  func register(keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) throws {
    let id = nextID
    var reference: EventHotKeyRef?
    let result = RegisterEventHotKey(
      keyCode, modifiers, EventHotKeyID(signature: signature, id: id),
      GetApplicationEventTarget(), 0, &reference
    )
    guard result == noErr, let reference else { throw ShortcutError.registration(result) }
    nextID += 1
    registrations.append(reference)
    actions[id] = action
  }

  deinit {
    for reference in registrations { UnregisterEventHotKey(reference) }
    if let handler { RemoveEventHandler(handler) }
  }
}

enum ShortcutError: LocalizedError {
  case registration(OSStatus)

  var errorDescription: String? {
    switch self {
    case .registration(let status):
      return "The shortcut could not be registered (\(status)). Another app may already use it. "
        + "Rocket is still available from the menu bar."
    }
  }
}
