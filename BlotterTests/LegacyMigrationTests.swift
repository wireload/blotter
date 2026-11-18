import Foundation
import Testing

@testable import Blotter

@MainActor
@Suite struct LegacyMigrationTests {
    @Test func unarchivesShortcutRecorderShortcuts() throws {
        let archiver = NSKeyedArchiver(requiringSecureCoding: false)
        archiver.setClassName("SRShortcut", for: LegacyShortcut.self)
        archiver.encode(LegacyShortcut(keyCode: 11, modifierFlags: 1_179_648), forKey: NSKeyedArchiveRootObjectKey)
        archiver.finishEncoding()

        let shortcut = try #require(LegacyShortcut.unarchive(archiver.encodedData))
        #expect(shortcut.keyCode == 11)
        #expect(shortcut.modifierFlags == 1_179_648)
    }

    @Test func rejectsOtherData() {
        #expect(LegacyShortcut.unarchive(Data("not an archive".utf8)) == nil)
    }

    @Test func migratesCalendarSelection() throws {
        let suite = "BlotterTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(
            ["store": ["work": ["isUsedForEvents": true, "isUsedForReminders": false, "IsEnabled": true]]],
            forKey: "Calendars")

        LegacyMigration.migrateCalendarSelection(defaults: defaults)

        #expect(defaults.stringArray(forKey: "HiddenEventCalendars") == [])
        #expect(defaults.stringArray(forKey: "HiddenReminderCalendars") == ["work"])
    }
}
