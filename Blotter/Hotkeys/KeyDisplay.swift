import AppKit
import BlotterKit
import Carbon.HIToolbox

/// How a shortcut looks: the symbols shown in Settings, and the key equivalent shown in menus.
enum KeyDisplay {
    /// For example "⌃⌥B" or "⌘F5", using the character the key types on the current keyboard layout.
    static func string(for combo: KeyCombo) -> String {
        combo.modifierSymbols + keyName(for: combo)
    }

    static func keyName(for combo: KeyCombo) -> String {
        if let name = combo.specialKeyName {
            return name == "Space" ? String(localized: "Space") : name
        }
        return character(for: combo.keyCode)?.uppercased() ?? "#\(combo.keyCode)"
    }

    /// The key equivalent and modifier mask for an `NSMenuItem`.
    static func menuEquivalent(for combo: KeyCombo) -> (key: String, modifiers: NSEvent.ModifierFlags) {
        let modifiers = NSEvent.ModifierFlags(rawValue: combo.modifiers.rawValue)
        if let special = menuKeys[combo.keyCode] {
            return (String(Character(UnicodeScalar(special) ?? " ")), modifiers)
        }
        return (character(for: combo.keyCode)?.lowercased() ?? "", modifiers)
    }

    /// The character a key types without modifiers, on the current layout (or an ASCII-capable one, for input
    /// methods such as Japanese that have no key layout of their own).
    static func character(for keyCode: UInt16) -> String? {
        for source in [
            TISCopyCurrentKeyboardLayoutInputSource(), TISCopyCurrentASCIICapableKeyboardLayoutInputSource(),
        ] {
            guard let source = source?.takeRetainedValue(),
                let pointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
            else { continue }
            let layout = Unmanaged<CFData>.fromOpaque(pointer).takeUnretainedValue() as Data
            var deadKeyState: UInt32 = 0
            var characters = [UniChar](repeating: 0, count: 4)
            var length = 0
            let status = layout.withUnsafeBytes { bytes -> OSStatus in
                guard let keyboard = bytes.bindMemory(to: UCKeyboardLayout.self).baseAddress else { return -1 }
                return UCKeyTranslate(
                    keyboard, keyCode, UInt16(kUCKeyActionDisplay), 0, UInt32(LMGetKbdType()),
                    OptionBits(kUCKeyTranslateNoDeadKeysMask), &deadKeyState, characters.count, &length,
                    &characters)
            }
            if status == noErr, length > 0 {
                let string = String(utf16CodeUnits: characters, count: length)
                if !string.trimmingCharacters(in: .controlCharacters).isEmpty {
                    return string
                }
            }
        }
        return nil
    }

    /// Key equivalents for keys that do not type a character, as AppKit's function-key code points.
    private static let menuKeys: [UInt16: Int] = [
        0x7A: NSF1FunctionKey, 0x78: NSF2FunctionKey, 0x63: NSF3FunctionKey, 0x76: NSF4FunctionKey,
        0x60: NSF5FunctionKey, 0x61: NSF6FunctionKey, 0x62: NSF7FunctionKey, 0x64: NSF8FunctionKey,
        0x65: NSF9FunctionKey, 0x6D: NSF10FunctionKey, 0x67: NSF11FunctionKey, 0x6F: NSF12FunctionKey,
        0x69: NSF13FunctionKey, 0x6B: NSF14FunctionKey, 0x71: NSF15FunctionKey, 0x6A: NSF16FunctionKey,
        0x40: NSF17FunctionKey, 0x4F: NSF18FunctionKey, 0x50: NSF19FunctionKey, 0x5A: NSF20FunctionKey,
        0x7B: NSLeftArrowFunctionKey, 0x7C: NSRightArrowFunctionKey, 0x7D: NSDownArrowFunctionKey,
        0x7E: NSUpArrowFunctionKey, 0x73: NSHomeFunctionKey, 0x77: NSEndFunctionKey,
        0x74: NSPageUpFunctionKey, 0x79: NSPageDownFunctionKey, 0x75: NSDeleteFunctionKey,
        0x24: 0x0D, 0x4C: 0x03, 0x30: 0x09, 0x31: 0x20, 0x33: 0x08, 0x35: 0x1B,
    ]
}
