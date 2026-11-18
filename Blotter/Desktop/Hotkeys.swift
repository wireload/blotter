import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleFront = Self("shortcutBringToFront")
    static let newEvent = Self("shortcutNewEvent")
    static let newReminder = Self("shortcutNewTask")
    static let nextWeek = Self("shortcutShowNextWeek")
    static let previousWeek = Self("shortcutShowPreviousWeek")
    static let currentWeek = Self("shortcutShowCurrentWeek")
}

/// Global keyboard shortcuts. None are assigned by default; the user records them in Settings.
enum Hotkeys {
    static func install(actions: any CalendarActions) {
        KeyboardShortcuts.onKeyUp(for: .toggleFront) { [weak actions] in actions?.toggleFront() }
        KeyboardShortcuts.onKeyUp(for: .newEvent) { [weak actions] in actions?.showNewEvent() }
        KeyboardShortcuts.onKeyUp(for: .newReminder) { [weak actions] in actions?.showNewReminder() }
        KeyboardShortcuts.onKeyUp(for: .nextWeek) { [weak actions] in actions?.showNextWeek() }
        KeyboardShortcuts.onKeyUp(for: .previousWeek) { [weak actions] in actions?.showPreviousWeek() }
        KeyboardShortcuts.onKeyUp(for: .currentWeek) { [weak actions] in actions?.showCurrentWeek() }
    }
}
