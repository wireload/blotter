import AppKit
import SwiftUI

/// Small floating windows for adding an event or a reminder.
final class ComposerWindowController {
    private let store: CalendarStore
    private var eventWindow: NSWindow?
    private var reminderWindow: NSWindow?

    init(store: CalendarStore) {
        self.store = store
    }

    /// Shows the New Event window. Returns `false` when there is no calendar to add events to.
    func showEvent() -> Bool {
        guard store.eventCalendars.contains(where: \.allowsModifications) else { return false }
        if let eventWindow, eventWindow.isVisible {
            // Keep the draft the user is working on.
            eventWindow.makeKeyAndOrderFront(nil)
            return true
        }
        let window = makeWindow(title: String(localized: "New Event"), autosaveName: "NewEventWindow")
        window.contentViewController = NSHostingController(
            rootView: NewEventView(close: { [weak window] in window?.close() }).environment(store))
        present(window)
        eventWindow = window
        return true
    }

    /// Shows the New Reminder window. Returns `false` when there is no list to add reminders to.
    func showReminder() -> Bool {
        guard store.reminderCalendars.contains(where: \.allowsModifications) else { return false }
        if let reminderWindow, reminderWindow.isVisible {
            reminderWindow.makeKeyAndOrderFront(nil)
            return true
        }
        let window = makeWindow(title: String(localized: "New Reminder"), autosaveName: "NewTaskWindow")
        window.contentViewController = NSHostingController(
            rootView: NewReminderView(close: { [weak window] in window?.close() }).environment(store))
        present(window)
        reminderWindow = window
        return true
    }

    private func makeWindow(title: String, autosaveName: String) -> NSWindow {
        let window = NSPanel(
            contentRect: .zero, styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered,
            defer: true)
        window.title = title
        window.titlebarAppearsTransparent = true
        // Above the calendar, which floats while it is brought to front.
        window.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 1)
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.setFrameAutosaveName(autosaveName)
        return window
    }

    private func present(_ window: NSWindow) {
        if !window.setFrameUsingName(window.frameAutosaveName) {
            window.center()
        }
        window.makeKeyAndOrderFront(nil)
    }
}
