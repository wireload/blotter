import AppKit
import BlotterKit

/// The menu bar item and its menu.
final class StatusItemController: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private weak var actions: (any CalendarActions)?
    private let state: CalendarState
    private var frontItem: NSMenuItem?
    private var shortcutItems: [(item: NSMenuItem, action: HotkeyAction)] = []
    private var visibilityObservation: NSKeyValueObservation?
    private var defaultsObserver: (any NSObjectProtocol)?

    init(actions: any CalendarActions, state: CalendarState) {
        self.actions = actions
        self.state = state
        super.init()

        statusItem.autosaveName = "net.wireload.blotter.mac.StatusItem"
        statusItem.behavior = .removalAllowed
        if let button = statusItem.button {
            let image = NSImage(named: "MenuBarIcon")
            image?.isTemplate = true
            button.image = image
            button.setAccessibilityLabel("Blotter")
        }
        statusItem.menu = makeMenu()
        statusItem.isVisible = UserDefaults.standard.bool(forKey: DefaultsKey.showsMenuBarItem)

        // Removing the item by ⌘-dragging it out of the menu bar turns the preference off.
        visibilityObservation = statusItem.observe(\.isVisible, options: [.new]) { _, change in
            let visible = change.newValue ?? true
            MainActor.assumeIsolated {
                if UserDefaults.standard.bool(forKey: DefaultsKey.showsMenuBarItem) != visible {
                    UserDefaults.standard.set(visible, forKey: DefaultsKey.showsMenuBarItem)
                }
            }
        }
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                let visible = UserDefaults.standard.bool(forKey: DefaultsKey.showsMenuBarItem)
                if self.statusItem.isVisible != visible {
                    self.statusItem.isVisible = visible
                }
            }
        }
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self

        let front = item(String(localized: "Bring to Front"), #selector(toggleFront), shortcut: .toggleFront)
        frontItem = front
        menu.addItem(front)
        menu.addItem(item(String(localized: "New Event…"), #selector(newEvent), shortcut: .newEvent))
        menu.addItem(item(String(localized: "New Reminder…"), #selector(newReminder), shortcut: .newReminder))
        menu.addItem(.separator())
        menu.addItem(item(String(localized: "Next Week"), #selector(nextWeek), shortcut: .nextWeek))
        menu.addItem(item(String(localized: "Current Week"), #selector(currentWeek), shortcut: .currentWeek))
        menu.addItem(item(String(localized: "Previous Week"), #selector(previousWeek), shortcut: .previousWeek))
        menu.addItem(.separator())
        let settings = item(String(localized: "Settings…"), #selector(settings))
        settings.keyEquivalent = ","
        menu.addItem(settings)
        menu.addItem(item(String(localized: "About Blotter"), #selector(about)))
        menu.addItem(.separator())
        let quit = NSMenuItem(
            title: String(localized: "Quit Blotter"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"
        )
        menu.addItem(quit)
        return menu
    }

    private func item(_ title: String, _ action: Selector, shortcut: HotkeyAction? = nil) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        if let shortcut {
            shortcutItems.append((item, shortcut))
        }
        return item
    }

    /// Shows each action's global shortcut next to it.
    private func updateShortcuts() {
        for (item, action) in shortcutItems {
            if let combo = HotkeyStore.shared.combo(for: action) {
                let equivalent = KeyDisplay.menuEquivalent(for: combo)
                item.keyEquivalent = equivalent.key
                item.keyEquivalentModifierMask = equivalent.modifiers
            } else {
                item.keyEquivalent = ""
                item.keyEquivalentModifierMask = []
            }
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        state.noteActivity()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        updateShortcuts()
        frontItem?.title =
            state.presentation == .front ? String(localized: "Send to Back") : String(localized: "Bring to Front")
    }

    @objc private func toggleFront() { actions?.toggleFront() }
    @objc private func newEvent() { actions?.showNewEvent() }
    @objc private func newReminder() { actions?.showNewReminder() }
    @objc private func nextWeek() { actions?.showNextWeek() }
    @objc private func currentWeek() { actions?.showCurrentWeek() }
    @objc private func previousWeek() { actions?.showPreviousWeek() }
    @objc private func settings() { actions?.showSettings() }
    @objc private func about() { actions?.showAbout() }
}
