import Foundation

/// Which days the calendar shows, and which events fall on each of them.
public enum Schedule {
    /// The days shown in the week view.
    ///
    /// - Parameters:
    ///   - weekOffset: Whole weeks forwards (positive) or backwards (negative) from the week containing `date`.
    ///   - rolling: Show seven days starting on the day of `date` instead of the calendar week.
    public static func days(containing date: Date, weekOffset: Int = 0, rolling: Bool, calendar: Calendar)
        -> [DateRange]
    {
        let first: Date
        let last: Date
        if rolling {
            let today = calendar.startOfDay(for: date)
            first = calendar.date(byAdding: .day, value: 7 * weekOffset, to: today) ?? today
            last = calendar.date(byAdding: .day, value: 7, to: first) ?? first
        } else {
            let shifted = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: date) ?? date
            let week = calendar.dateInterval(of: .weekOfYear, for: shifted) ?? DateInterval(start: shifted, duration: 0)
            first = week.start
            last = week.end
        }
        return DateRange(start: first, end: last).split(by: .day, in: calendar)
    }

    /// Wall-clock hour of `date` on `day` (for example 13.5 for 13:30), clamped to 0…24.
    ///
    /// Uses clock time rather than elapsed time, so hours line up with the time ruler on daylight-saving days.
    public static func hour(of date: Date, on day: DateRange, calendar: Calendar) -> Double {
        if date <= day.start { return 0 }
        if date >= day.end { return 24 }
        let components = calendar.dateComponents([.hour, .minute, .second], from: date)
        let hour =
            Double(components.hour ?? 0) + Double(components.minute ?? 0) / 60 + Double(components.second ?? 0) / 3_600
        return min(max(hour, 0), 24)
    }

    /// Events on one day.
    public struct Day: Identifiable, Sendable {
        public var range: DateRange
        /// Shown in the all-day area: all-day events, and timed events covering the whole day.
        public var allDay: [Event]
        /// Timed events, with the part of each that falls on this day.
        public var timed: [(event: Event, part: DateRange)]

        public var id: Date { range.start }
    }

    /// Distributes `events` over `days`. Events spanning several days appear on each of them.
    public static func arrange(_ events: [Event], into days: [DateRange]) -> [Day] {
        days.map { day in
            var allDay: [Event] = []
            var timed: [(event: Event, part: DateRange)] = []

            for event in events {
                let range = event.range
                guard range.intersects(day) || (range.isEmpty && day.position(of: range.start) == .within) else {
                    continue
                }
                let part = DateRange(start: max(range.start, day.start), end: min(range.end, day.end))
                if event.isAllDay || (part.start == day.start && part.end == day.end) {
                    allDay.append(event)
                } else {
                    timed.append((event, part))
                }
            }

            allDay.sort { a, b in
                if a.range.duration != b.range.duration { return a.range.duration > b.range.duration }
                if a.calendarID != b.calendarID { return a.calendarID < b.calendarID }
                if a.title != b.title { return a.title < b.title }
                return a.id < b.id
            }
            timed.sort { a, b in
                if a.part.start != b.part.start { return a.part.start < b.part.start }
                if a.event.id != b.event.id { return a.event.id < b.event.id }
                return a.event.calendarID < b.event.calendarID
            }
            return Day(range: day, allDay: allDay, timed: timed)
        }
    }
}
