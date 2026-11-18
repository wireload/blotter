import Foundation

/// An sRGB colour with components in 0–1, so that calendar colours can cross into platform-independent code.
public struct RGBAColor: Hashable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// Fallback for calendars without a colour.
    public static let fallback = RGBAColor(red: 0.2, green: 0.45, blue: 0.95)
}

/// A calendar event, independent of EventKit.
public struct Event: Identifiable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var location: String?
    public var start: Date
    public var end: Date
    public var isAllDay: Bool
    public var calendarID: String
    public var color: RGBAColor

    public init(
        id: String, title: String, location: String? = nil, start: Date, end: Date, isAllDay: Bool = false,
        calendarID: String, color: RGBAColor = .fallback
    ) {
        self.id = id
        self.title = title
        self.location = location
        self.start = start
        self.end = max(end, start)
        self.isAllDay = isAllDay
        self.calendarID = calendarID
        self.color = color
    }

    public var range: DateRange { DateRange(start: start, end: end) }
}

/// An incomplete reminder, independent of EventKit.
public struct Reminder: Identifiable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var dueDate: Date?
    /// EventKit priority: 0 = none, 1 = highest … 9 = lowest.
    public var priority: Int
    public var calendarID: String
    public var calendarTitle: String
    public var color: RGBAColor

    public init(
        id: String, title: String, dueDate: Date? = nil, priority: Int = 0, calendarID: String,
        calendarTitle: String = "", color: RGBAColor = .fallback
    ) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.priority = priority
        self.calendarID = calendarID
        self.calendarTitle = calendarTitle
        self.color = color
    }

    /// Blotter's To Do order: due date (undated last), priority (highest first, none last), calendar, title.
    public static func areInDisplayOrder(_ a: Reminder, _ b: Reminder) -> Bool {
        switch (a.dueDate, b.dueDate) {
        case let (x?, y?) where x != y: return x < y
        case (.some, nil): return true
        case (nil, .some): return false
        default: break
        }

        let pa = a.priority == 0 ? Int.max : a.priority
        let pb = b.priority == 0 ? Int.max : b.priority
        if pa != pb { return pa < pb }

        if a.calendarTitle != b.calendarTitle {
            return a.calendarTitle.localizedStandardCompare(b.calendarTitle) == .orderedAscending
        }
        let titleOrder = a.title.localizedStandardCompare(b.title)
        if titleOrder != .orderedSame { return titleOrder == .orderedAscending }
        return a.id < b.id
    }
}
