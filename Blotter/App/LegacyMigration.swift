import AppKit
import BlotterKit
import OSLog
import ServiceManagement

/// Carries over the Blotter 2.x settings that 3.0 stores differently: calendar selection, global shortcuts and the
/// login item. Runs once, and only for users upgrading from 2.x.
enum LegacyMigration {
    private static let doneKey = "MigratedFromBlotter2"
    /// Written by every Blotter 2.x release; its presence identifies an upgrade.
    private static let legacyVersionKey = "LastMigratedBundleVersion"
    private static let legacyCalendarsKey = "Calendars"
    private static let legacyLoginItem = "net.wireload.blotter.mac.LoginItem"
    private static let log = Logger(subsystem: "net.wireload.blotter.mac", category: "Migration")

    static func runIfNeeded(defaults: UserDefaults = .standard) {
        guard !defaults.bool(forKey: doneKey) else { return }
        defer { defaults.set(true, forKey: doneKey) }
        guard defaults.object(forKey: legacyVersionKey) != nil else { return }

        migrateCalendarSelection(defaults: defaults)
        migrateShortcuts(defaults: defaults)
        migrateLoginItem()
        log.info("Migrated settings from Blotter 2")
    }

    // MARK: Calendars

    /// 2.x stored `{storeID: {calendarID: {isUsedForEvents, isUsedForReminders, IsEnabled}}}`; 3.0 stores the IDs of
    /// hidden calendars. Calendar IDs are the same in both (EventKit calendar identifiers).
    static func migrateCalendarSelection(defaults: UserDefaults) {
        guard let stores = defaults.dictionary(forKey: legacyCalendarsKey) as? [String: [String: [String: Any]]] else {
            return
        }
        let hidden = LegacySettings.hiddenCalendars(from: stores)
        defaults.set(hidden.events.sorted(), forKey: DefaultsKey.hiddenEventCalendars)
        defaults.set(hidden.reminders.sorted(), forKey: DefaultsKey.hiddenReminderCalendars)
    }

    // MARK: Shortcuts

    private static let legacyShortcuts: [(key: String, action: HotkeyAction)] = [
        ("shortcutBringToFront", .toggleFront),
        ("shortcutNewEvent", .newEvent),
        ("shortcutNewTask", .newReminder),
        ("shortcutShowNextWeek", .nextWeek),
        ("shortcutShowPreviousWeek", .previousWeek),
        ("shortcutShowCurrentWeek", .currentWeek),
    ]

    /// 2.x stored ShortcutRecorder's `SRShortcut`, keyed-archived, under the same names.
    static func migrateShortcuts(defaults: UserDefaults, store: HotkeyStore = .shared) {
        for (key, action) in legacyShortcuts {
            guard store.combo(for: action) == nil,
                let data = defaults.data(forKey: key),
                let legacy = LegacyShortcut.unarchive(data),
                let combo = KeyCombo(legacyKeyCode: legacy.keyCode, modifierFlags: legacy.modifierFlags),
                KeyCombo.conflict(for: combo, assigningTo: action, in: store.combos) == nil
            else { continue }
            store.set(combo, for: action)
        }
    }

    // MARK: Login item

    /// 2.x launched at login through a helper app registered with `SMLoginItemSetEnabled`. The helper is gone, so
    /// turn it off and register the app itself instead.
    private static func migrateLoginItem() {
        let legacy = SMAppService.loginItem(identifier: legacyLoginItem)
        guard legacy.status == .enabled else { return }
        do {
            try? legacy.unregister()
            try SMAppService.mainApp.register()
        } catch {
            log.error("Could not migrate the login item: \(error.localizedDescription, privacy: .public)")
        }
    }
}

/// Reads ShortcutRecorder's archived `SRShortcut` without linking ShortcutRecorder.
@objc(BlotterLegacyShortcut)
nonisolated final class LegacyShortcut: NSObject, NSCoding {
    let keyCode: Int
    let modifierFlags: UInt

    init(keyCode: Int, modifierFlags: UInt) {
        self.keyCode = keyCode
        self.modifierFlags = modifierFlags
    }

    init?(coder: NSCoder) {
        guard let keyCode = coder.decodeObject(forKey: "keyCode") as? NSNumber else { return nil }
        self.keyCode = keyCode.intValue
        modifierFlags = (coder.decodeObject(forKey: "modifierFlags") as? NSNumber)?.uintValue ?? 0
    }

    func encode(with coder: NSCoder) {
        coder.encode(NSNumber(value: keyCode), forKey: "keyCode")
        coder.encode(NSNumber(value: modifierFlags), forKey: "modifierFlags")
    }

    static func unarchive(_ data: Data) -> LegacyShortcut? {
        guard let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: data) else { return nil }
        unarchiver.requiresSecureCoding = false
        unarchiver.setClass(LegacyShortcut.self, forClassName: "SRShortcut")
        defer { unarchiver.finishDecoding() }
        return unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? LegacyShortcut
    }
}
