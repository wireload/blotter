import AppKit
import SwiftUI

/// The Settings window: a toolbar of panes, each a SwiftUI form.
final class SettingsWindowController: NSWindowController {
    enum Pane: Int, CaseIterable {
        case general, shortcuts, position, layout, calendars, about

        var title: String {
            switch self {
            case .general: String(localized: "General")
            case .shortcuts: String(localized: "Shortcuts")
            case .position: String(localized: "Position")
            case .layout: String(localized: "Layout")
            case .calendars: String(localized: "Calendars")
            case .about: String(localized: "About")
            }
        }

        var symbol: String {
            switch self {
            case .general: "gearshape"
            case .shortcuts: "keyboard"
            case .position: "macwindow"
            case .layout: "rectangle.split.3x1"
            case .calendars: "calendar"
            case .about: "info.circle"
            }
        }
    }

    private let tabs = NSTabViewController()

    init(store: CalendarStore) {
        tabs.tabStyle = .toolbar
        tabs.canPropagateSelectedChildViewControllerTitle = true

        for pane in Pane.allCases {
            let controller = NSHostingController(rootView: Self.view(for: pane).environment(store))
            controller.sizingOptions = .preferredContentSize
            controller.title = pane.title
            let item = NSTabViewItem(viewController: controller)
            item.label = pane.title
            item.image = NSImage(systemSymbolName: pane.symbol, accessibilityDescription: pane.title)
            tabs.addTabViewItem(item)
        }

        let window = NSWindow(contentViewController: tabs)
        window.styleMask = [.titled, .closable]
        window.toolbarStyle = .preference
        window.isReleasedWhenClosed = false
        // Above the calendar when it is brought to front (which floats), like Blotter 2's preferences and the
        // New Event window.
        window.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 1)
        window.setFrameAutosaveName("Settings")
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func show(pane: Pane? = nil) {
        if let pane {
            tabs.selectedTabViewItemIndex = pane.rawValue
        }
        if let window, !window.isVisible, !window.setFrameUsingName("Settings") {
            window.center()
        }
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    @ViewBuilder
    private static func view(for pane: Pane) -> some View {
        Group {
            switch pane {
            case .general: GeneralSettings()
            case .shortcuts: ShortcutSettings()
            case .position: PositionSettings()
            case .layout: LayoutSettings()
            case .calendars: CalendarSettings()
            case .about: AboutSettings()
            }
        }
        .formStyle(.grouped)
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
    }
}
