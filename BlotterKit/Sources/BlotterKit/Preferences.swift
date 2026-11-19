import Foundation

/// How large the calendar is on its screen. Raw values match the defaults written by Blotter 2.x.
public enum CalendarSize: Int, CaseIterable, Identifiable, Sendable {
    case narrow = 0
    case normal = 1
    case full = 2
    case custom = 3

    public var id: Int { rawValue }
}

/// Where a non-custom calendar is anchored on its screen. Raw values match the defaults written by Blotter 2.x.
public enum CalendarPosition: Int, CaseIterable, Identifiable, Sendable {
    case topLeft = 0
    case topCenter = 1
    case topRight = 2
    case centerLeft = 3
    case center = 4
    case centerRight = 5
    case bottomLeft = 6
    case bottomCenter = 7
    case bottomRight = 8

    public var id: Int { rawValue }

    /// Where a new calendar goes: bottom right. Since macOS Sonoma, desktop widgets fill the top left, and
    /// Notification Center and desktop icons start at the top right.
    public static let defaultPosition = CalendarPosition.bottomRight

    /// 0 = left, 1 = centre, 2 = right.
    public var column: Int { rawValue % 3 }
    /// 0 = top, 1 = centre, 2 = bottom.
    public var row: Int { rawValue / 3 }
}

/// Which panes share the info column next to the week. Raw values match the defaults written by Blotter 2.x.
public enum CalendarLayout: Int, CaseIterable, Identifiable, Sendable {
    /// To Do and Right Now split the column evenly.
    case normal = 0
    /// To Do and Right Now, split at the user's To Do height.
    case custom = 1
    /// Only To Do.
    case toDo = 2
    /// Only Right Now.
    case rightNow = 3

    public var id: Int { rawValue }
}

/// User defaults keys. Keys shared with Blotter 2.x keep their names so existing preferences carry over.
public enum DefaultsKey {
    public static let calendarSize = "CalendarSize"
    public static let calendarPosition = "CalendarPosition"
    public static let customFrame = "CustomFrame"
    public static let screenID = "ScreenUUID"
    public static let calendarLayout = "CalendarLayout"
    public static let infoWidth = "InfoViewsWidth"
    public static let dateHeight = "DateViewHeight"
    public static let toDoHeight = "TasksViewHeight"
    public static let allDayHeight = "AllDayViewHeight"
    public static let showsAllCalendars = "DisplayAllCalendars"
    public static let hiddenEventCalendars = "HiddenEventCalendars"
    public static let hiddenReminderCalendars = "HiddenReminderCalendars"
    public static let showsMenuBarItem = "ShowInMenuBar"
    public static let autoFades = "AutoFade"
    public static let autoFadeSeconds = "AutoFadeSeconds"
    public static let showsNext7Days = "RollingCalendar"
    public static let showsWeekdayDates = "PerDayDate"
    public static let lastEventCalendar = "uidOfLastSelectedCalendarInEvents"
    public static let lastReminderCalendar = "uidOfLastSelectedCalendarInTasks"
}
