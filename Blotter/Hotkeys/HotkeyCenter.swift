import AppKit
import BlotterKit
import Carbon.HIToolbox
import OSLog

/// Registers the global shortcuts with the system.
///
/// Uses Carbon's `RegisterEventHotKey`: it is the only API that delivers system-wide shortcuts to a sandboxed app
/// without asking for Accessibility access, and the system consumes the key press so it does not reach other apps.
final class HotkeyCenter {
    static let shared = HotkeyCenter()

    /// Shortcuts that could not be registered, typically because another app already uses them.
    private(set) var failed: Set<HotkeyAction> = []

    private var perform: ((HotkeyAction) -> Void)?
    private var registered: [HotkeyAction: EventHotKeyRef] = [:]
    private var handler: EventHandlerRef?
    private var isPaused = false
    private let log = Logger(subsystem: "net.wireload.blotter.mac", category: "Hotkeys")

    /// 'BLTR', identifying Blotter's shortcuts in hot key events.
    private static let signature: OSType = 0x424C_5452

    /// Starts listening, and registers the stored shortcuts. `perform` runs when one is pressed.
    func start(store: HotkeyStore, perform: @escaping (HotkeyAction) -> Void) {
        self.perform = perform
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), hotkeyEventHandler, 1, &eventType, nil, &handler)
        store.onChange = { [weak self, weak store] in
            guard let store else { return }
            self?.register(store.combos)
        }
        register(store.combos)
    }

    /// Stops the shortcuts from firing, while the user records a new one.
    func pause() {
        isPaused = true
        unregisterAll()
    }

    func resume(store: HotkeyStore) {
        isPaused = false
        register(store.combos)
    }

    fileprivate func handle(id: UInt32) {
        guard !isPaused, Int(id) < HotkeyAction.allCases.count else { return }
        perform?(HotkeyAction.allCases[Int(id)])
    }

    private func register(_ combos: [HotkeyAction: KeyCombo]) {
        unregisterAll()
        guard !isPaused else { return }
        failed = []
        for (index, action) in HotkeyAction.allCases.enumerated() {
            guard let combo = combos[action] else { continue }
            var ref: EventHotKeyRef?
            let status = RegisterEventHotKey(
                UInt32(combo.keyCode), combo.carbonModifiers,
                EventHotKeyID(signature: Self.signature, id: UInt32(index)),
                GetApplicationEventTarget(), 0, &ref)
            if status == noErr, let ref {
                registered[action] = ref
            } else {
                failed.insert(action)
                log.error("Could not register the shortcut for \(action.rawValue, privacy: .public): \(status)")
            }
        }
    }

    private func unregisterAll() {
        for ref in registered.values {
            UnregisterEventHotKey(ref)
        }
        registered = [:]
    }

    /// Whether macOS reserves `combo` for one of its own shortcuts (Spotlight, Mission Control, screenshots, …).
    static func isReservedBySystem(_ combo: KeyCombo) -> Bool {
        var unmanaged: Unmanaged<CFArray>?
        guard CopySymbolicHotKeys(&unmanaged) == noErr,
            let hotkeys = unmanaged?.takeRetainedValue() as? [[String: Any]]
        else { return false }
        return hotkeys.contains { hotkey in
            (hotkey["kHISymbolicHotKeyEnabled"] as? Bool) == true
                && (hotkey["kHISymbolicHotKeyCode"] as? Int) == Int(combo.keyCode)
                && (hotkey["kHISymbolicHotKeyModifiers"] as? Int).map { UInt32($0) & 0x1B00 } == combo.carbonModifiers
        }
    }
}

/// Carbon calls this on the main thread for every hot key press.
private nonisolated func hotkeyEventHandler(
    _ next: EventHandlerCallRef?, _ event: EventRef?, _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event else { return OSStatus(eventNotHandledErr) }
    var id = EventHotKeyID()
    let status = GetEventParameter(
        event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil,
        MemoryLayout<EventHotKeyID>.size, nil, &id)
    guard status == noErr, id.signature == 0x424C_5452 else { return OSStatus(eventNotHandledErr) }
    MainActor.assumeIsolated {
        HotkeyCenter.shared.handle(id: id.id)
    }
    return noErr
}
