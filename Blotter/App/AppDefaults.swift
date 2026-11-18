import AppKit
import BlotterKit

/// Registers default values and reads preferences that need more than a plain `@AppStorage`.
enum AppDefaults {
    static let showsSettingsAtLaunch = "ShowPreferencesAtStartUp"
    static let appearance = "Appearance"
    /// Custom frame as written by Blotter 2.x (an `NSStringFromRect` string), migrated to `DefaultsKey.customFrame`.
    private static let legacyCustomFrame = "CustomFrameFactors"

    static func register() {
        let metrics = PaneLayout.Metrics()
        UserDefaults.standard.register(defaults: [
            DefaultsKey.calendarSize: CalendarSize.normal.rawValue,
            DefaultsKey.calendarPosition: CalendarPosition.topLeft.rawValue,
            DefaultsKey.calendarLayout: CalendarLayout.normal.rawValue,
            DefaultsKey.infoWidth: Double(metrics.infoWidth),
            DefaultsKey.dateHeight: Double(metrics.dateHeight),
            DefaultsKey.toDoHeight: Double(metrics.toDoHeight),
            DefaultsKey.allDayHeight: Double(metrics.allDayHeight),
            DefaultsKey.showsAllCalendars: true,
            DefaultsKey.showsMenuBarItem: true,
            DefaultsKey.autoFades: false,
            DefaultsKey.autoFadeSeconds: 60,
            DefaultsKey.showsNext7Days: false,
            DefaultsKey.showsWeekdayDates: true,
            showsSettingsAtLaunch: true,
            appearance: AppAppearance.system.rawValue,
        ])
        migrateLegacyCustomFrame()
    }

    /// Custom frame factors (fractions of the screen's visible frame, bottom-left origin).
    static var customFrame: CGRect {
        get {
            let values = UserDefaults.standard.array(forKey: DefaultsKey.customFrame) as? [Double] ?? []
            guard values.count == 4 else { return WindowGeometry.defaultCustomFactors }
            return WindowGeometry.sanitized(CGRect(x: values[0], y: values[1], width: values[2], height: values[3]))
        }
        set {
            let factors = WindowGeometry.sanitized(newValue)
            UserDefaults.standard.set(
                [factors.minX, factors.minY, factors.width, factors.height].map(Double.init),
                forKey: DefaultsKey.customFrame)
        }
    }

    private static func migrateLegacyCustomFrame() {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: DefaultsKey.customFrame) == nil,
            let legacy = defaults.string(forKey: legacyCustomFrame)
        else { return }
        let rect = NSRectFromString(legacy)
        if rect.width > 0, rect.height > 0 {
            customFrame = rect
        }
    }
}

/// Whether the calendar follows the system appearance or always uses light or dark.
enum AppAppearance: Int, CaseIterable, Identifiable {
    case system = 0
    case light = 1
    case dark = 2

    var id: Int { rawValue }

    var appearanceName: NSAppearance.Name? {
        switch self {
        case .system: nil
        case .light: .aqua
        case .dark: .darkAqua
        }
    }
}
