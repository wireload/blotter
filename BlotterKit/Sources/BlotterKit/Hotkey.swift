import Foundation

/// The actions that can have a global keyboard shortcut.
public enum HotkeyAction: String, CaseIterable, Codable, Sendable {
    case toggleFront
    case newEvent
    case newReminder
    case nextWeek
    case previousWeek
    case currentWeek

    /// Where the shortcut is stored in user defaults.
    public var defaultsKey: String { "Hotkey." + rawValue }
}

/// A key and its modifiers, as pressed on the keyboard.
public struct KeyCombo: Codable, Hashable, Sendable {
    /// Modifier keys. Raw values match AppKit's device-independent `NSEvent.ModifierFlags`.
    public struct Modifiers: OptionSet, Codable, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let shift = Modifiers(rawValue: 1 << 17)
        public static let control = Modifiers(rawValue: 1 << 18)
        public static let option = Modifiers(rawValue: 1 << 19)
        public static let command = Modifiers(rawValue: 1 << 20)

        public static let all: Modifiers = [.shift, .control, .option, .command]
    }

    /// Virtual key code (`kVK_…`), independent of the keyboard layout.
    public var keyCode: UInt16
    public var modifiers: Modifiers

    public init(keyCode: UInt16, modifiers: Modifiers) {
        self.keyCode = keyCode
        self.modifiers = modifiers.intersection(.all)
    }

    /// Converts a ShortcutRecorder shortcut stored by Blotter 2.x (key code and Cocoa modifier flags).
    public init?(legacyKeyCode keyCode: Int, modifierFlags: UInt) {
        guard let code = UInt16(exactly: keyCode) else { return nil }
        self.init(keyCode: code, modifiers: Modifiers(rawValue: modifierFlags))
        guard isValid else { return nil }
    }

    /// Modifiers in Carbon's format, for `RegisterEventHotKey`.
    public var carbonModifiers: UInt32 {
        var flags: UInt32 = 0
        if modifiers.contains(.command) { flags |= 0x0100 }  // cmdKey
        if modifiers.contains(.shift) { flags |= 0x0200 }  // shiftKey
        if modifiers.contains(.option) { flags |= 0x0800 }  // optionKey
        if modifiers.contains(.control) { flags |= 0x1000 }  // controlKey
        return flags
    }

    /// Modifier symbols in the order macOS shows them: ⌃⌥⇧⌘.
    public var modifierSymbols: String {
        var symbols = ""
        if modifiers.contains(.control) { symbols += "⌃" }
        if modifiers.contains(.option) { symbols += "⌥" }
        if modifiers.contains(.shift) { symbols += "⇧" }
        if modifiers.contains(.command) { symbols += "⌘" }
        return symbols
    }

    /// Whether the key is a function key (F1–F20), which may be used without modifiers.
    public var isFunctionKey: Bool { Self.functionKeys.keys.contains(keyCode) }

    /// A global shortcut needs ⌘, ⌥ or ⌃ (Shift alone would block typing capitals), unless it is a function key.
    public var isValid: Bool {
        isFunctionKey || !modifiers.isDisjoint(with: [.command, .option, .control])
    }

    /// The symbol or name printed on keys that do not type a character, or `nil` for character keys.
    public var specialKeyName: String? {
        Self.functionKeys[keyCode] ?? Self.specialKeys[keyCode]
    }

    static let functionKeys: [UInt16: String] = [
        0x7A: "F1", 0x78: "F2", 0x63: "F3", 0x76: "F4", 0x60: "F5", 0x61: "F6", 0x62: "F7", 0x64: "F8",
        0x65: "F9", 0x6D: "F10", 0x67: "F11", 0x6F: "F12", 0x69: "F13", 0x6B: "F14", 0x71: "F15",
        0x6A: "F16", 0x40: "F17", 0x4F: "F18", 0x50: "F19", 0x5A: "F20",
    ]

    static let specialKeys: [UInt16: String] = [
        0x24: "↩", 0x4C: "⌤", 0x30: "⇥", 0x31: "Space", 0x33: "⌫", 0x75: "⌦", 0x35: "⎋",
        0x73: "↖", 0x77: "↘", 0x74: "⇞", 0x79: "⇟",
        0x7B: "←", 0x7C: "→", 0x7D: "↓", 0x7E: "↑",
    ]
}

extension KeyCombo {
    /// The other action already using `combo`, if any.
    public static func conflict(
        for combo: KeyCombo, assigningTo action: HotkeyAction, in assignments: [HotkeyAction: KeyCombo]
    ) -> HotkeyAction? {
        HotkeyAction.allCases.first { $0 != action && assignments[$0] == combo }
    }
}
