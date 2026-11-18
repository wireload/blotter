import AppKit
import BlotterKit

/// Actions available from the menu bar item and global keyboard shortcuts.
protocol CalendarActions: AnyObject {
    func toggleFront()
    func showNewEvent()
    func showNewReminder()
    /// Without full access, or without a calendar that can be edited, there is nowhere to add the new item.
    private func explainCannotAdd(_ message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = String(
            localized: "Blotter needs full access to your calendars and reminders, and a calendar or list it can edit.")
        alert.addButton(withTitle: String(localized: "Open Privacy & Security Settings…"))
        alert.addButton(withTitle: String(localized: "Cancel"))
        if alert.runModal() == .alertFirstButtonReturn,
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")
        {
            NSWorkspace.shared.open(url)
        }
    }

    func showNextWeek()
    func showPreviousWeek()
    func showCurrentWeek()
    func showSettings()
    func showAbout()
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let clock = Clock()
    let store = CalendarStore()
    let state = CalendarState()

    private var desktopWindow: DesktopWindowController?
    private var statusItem: StatusItemController?
    private lazy var settingsWindow = SettingsWindowController(store: store)
    private lazy var composer = ComposerWindowController(store: store)

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDefaults.register()
        LegacyMigration.runIfNeeded()

        let desktopWindow = DesktopWindowController(clock: clock, store: store, state: state)
        desktopWindow.onCancel = { [weak self] in self?.sendToBack() }
        desktopWindow.showWindow(nil)
        self.desktopWindow = desktopWindow

        statusItem = StatusItemController(actions: self, state: state)
        Hotkeys.install(actions: self)
        state.noteActivity()

        store.requestAccess()

        let defaults = UserDefaults.standard
        if defaults.bool(forKey: AppDefaults.showsSettingsAtLaunch) {
            defaults.set(false, forKey: AppDefaults.showsSettingsAtLaunch)
            showSettings()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // With the menu bar item hidden, launching Blotter again is the way back into Settings.
        showSettings()
        return false
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        state.noteActivity()
        store.refreshAccess()
    }

    func applicationDidResignActive(_ notification: Notification) {
        state.sendToBack()
    }

    private func sendToBack() {
        state.sendToBack()
        let otherWindows = NSApp.windows.filter {
            $0.isVisible && $0 !== desktopWindow?.window && $0.level != .statusBar
        }
        if otherWindows.isEmpty {
            NSApp.hide(nil)
        }
    }

    private func activate() {
        NSApp.activate()
    }
}

extension AppDelegate: CalendarActions {
    func toggleFront() {
        if state.presentation == .front {
            sendToBack()
        } else {
            state.bringToFront()
            activate()
        }
    }

    func showNewEvent() {
        state.noteActivity()
        activate()
        if !composer.showEvent() {
            explainCannotAdd(String(localized: "Blotter can’t add events"))
        }
    }

    func showNewReminder() {
        state.noteActivity()
        activate()
        if !composer.showReminder() {
            explainCannotAdd(String(localized: "Blotter can’t add reminders"))
        }
    }

    func showNextWeek() { state.navigate(to: state.weekOffset + 1) }

    func showPreviousWeek() { state.navigate(to: state.weekOffset - 1) }

    func showCurrentWeek() { state.navigate(to: 0) }

    func showSettings() {
        state.noteActivity()
        settingsWindow.show()
        activate()
    }

    func showAbout() {
        state.noteActivity()
        settingsWindow.show(pane: .about)
        activate()
    }
}
