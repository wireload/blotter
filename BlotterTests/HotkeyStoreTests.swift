import BlotterKit
import Foundation
import Testing

@testable import Blotter

@MainActor
@Suite struct HotkeyStoreTests {
    let commandShiftB = KeyCombo(keyCode: 0x0B, modifiers: [.command, .shift])

    private func scratchDefaults() throws -> (UserDefaults, String) {
        let suite = "BlotterTests.\(UUID().uuidString)"
        return (try #require(UserDefaults(suiteName: suite)), suite)
    }

    @Test func persistsAndClears() throws {
        let (defaults, suite) = try scratchDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }

        HotkeyStore(defaults: defaults).set(commandShiftB, for: .newEvent)
        #expect(HotkeyStore(defaults: defaults).combo(for: .newEvent) == commandShiftB)

        HotkeyStore(defaults: defaults).set(nil, for: .newEvent)
        #expect(HotkeyStore(defaults: defaults).combo(for: .newEvent) == nil)
    }

    @Test func validation() throws {
        let (defaults, suite) = try scratchDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = HotkeyStore(defaults: defaults)
        store.set(commandShiftB, for: .newEvent)

        #expect(store.validate(KeyCombo(keyCode: 0x0B, modifiers: [.shift]), for: .toggleFront) == .needsModifier)
        #expect(store.validate(commandShiftB, for: .toggleFront) == .usedBy(.newEvent))
        #expect(store.validate(commandShiftB, for: .newEvent) == nil)
    }

    @Test func migratesShortcutRecorderShortcuts() throws {
        let (defaults, suite) = try scratchDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let archiver = NSKeyedArchiver(requiringSecureCoding: false)
        archiver.setClassName("SRShortcut", for: LegacyShortcut.self)
        archiver.encode(LegacyShortcut(keyCode: 11, modifierFlags: 1_179_648), forKey: NSKeyedArchiveRootObjectKey)
        archiver.finishEncoding()
        defaults.set(archiver.encodedData, forKey: "shortcutBringToFront")

        let store = HotkeyStore(defaults: defaults)
        LegacyMigration.migrateShortcuts(defaults: defaults, store: store)

        #expect(store.combo(for: .toggleFront) == commandShiftB)
    }
}
