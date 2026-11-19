import Foundation
import Testing

@testable import BlotterKit

@Suite struct HotkeyTests {
    let commandShiftB = KeyCombo(keyCode: 0x0B, modifiers: [.command, .shift])

    @Test func modifierSymbolsInMacOrder() {
        #expect(KeyCombo(keyCode: 0x0B, modifiers: [.command, .shift, .option, .control]).modifierSymbols == "⌃⌥⇧⌘")
        #expect(commandShiftB.modifierSymbols == "⇧⌘")
    }

    @Test func carbonModifiers() {
        #expect(commandShiftB.carbonModifiers == 0x0100 | 0x0200)
        #expect(KeyCombo(keyCode: 0, modifiers: [.option, .control]).carbonModifiers == 0x0800 | 0x1000)
    }

    @Test func validity() {
        #expect(commandShiftB.isValid)
        #expect(!KeyCombo(keyCode: 0x0B, modifiers: []).isValid)
        #expect(!KeyCombo(keyCode: 0x0B, modifiers: [.shift]).isValid)
        #expect(KeyCombo(keyCode: 0x60, modifiers: []).isValid)  // F5
    }

    @Test func ignoresOtherModifierBits() {
        // Caps Lock (1 << 16) and device-dependent bits are dropped.
        let combo = KeyCombo(keyCode: 0x0B, modifiers: KeyCombo.Modifiers(rawValue: 1 << 16 | 1 << 20 | 0x8))
        #expect(combo.modifiers == [.command])
    }

    @Test func specialKeyNames() {
        #expect(KeyCombo(keyCode: 0x7A, modifiers: []).specialKeyName == "F1")
        #expect(KeyCombo(keyCode: 0x7E, modifiers: [.command]).specialKeyName == "↑")
        #expect(commandShiftB.specialKeyName == nil)
    }

    @Test func legacyShortcutRecorderValues() {
        // ⌘⇧B as stored by ShortcutRecorder: key code 11, Cocoa flags for Shift and Command.
        #expect(KeyCombo(legacyKeyCode: 11, modifierFlags: 1_179_648) == commandShiftB)
        #expect(KeyCombo(legacyKeyCode: 11, modifierFlags: 0) == nil)
        #expect(KeyCombo(legacyKeyCode: -1, modifierFlags: 1_179_648) == nil)
    }

    @Test func codableRoundTrip() throws {
        let data = try JSONEncoder().encode(commandShiftB)
        #expect(try JSONDecoder().decode(KeyCombo.self, from: data) == commandShiftB)
    }

    @Test func conflicts() {
        let assignments: [HotkeyAction: KeyCombo] = [.newEvent: commandShiftB]
        #expect(KeyCombo.conflict(for: commandShiftB, assigningTo: .toggleFront, in: assignments) == .newEvent)
        #expect(KeyCombo.conflict(for: commandShiftB, assigningTo: .newEvent, in: assignments) == nil)
    }
}
