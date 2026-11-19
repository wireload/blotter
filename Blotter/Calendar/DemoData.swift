import BlotterKit
import Foundation

/// Sample calendars, events and reminders for screenshots and UI work, used instead of EventKit when Blotter is
/// launched with `-BlotterDemoData YES`.
enum DemoData {
    static let defaultsKey = "BlotterDemoData"

    static var isEnabled: Bool { UserDefaults.standard.bool(forKey: defaultsKey) }

    private static let work = CalendarInfo(
        id: "demo-work", title: "Work", sourceTitle: "Demo", color: RGBAColor(red: 0.20, green: 0.47, blue: 0.96),
        allowsModifications: true)
    private static let home = CalendarInfo(
        id: "demo-home", title: "Home", sourceTitle: "Demo", color: RGBAColor(red: 0.30, green: 0.75, blue: 0.40),
        allowsModifications: true)
    private static let family = CalendarInfo(
        id: "demo-family", title: "Family", sourceTitle: "Demo", color: RGBAColor(red: 0.95, green: 0.55, blue: 0.20),
        allowsModifications: true)
    private static let tasks = CalendarInfo(
        id: "demo-tasks", title: "Tasks", sourceTitle: "Demo", color: RGBAColor(red: 0.85, green: 0.30, blue: 0.55),
        allowsModifications: true)

    static let eventCalendars = [work, home, family]
    static let reminderCalendars = [tasks, home]

    /// Events for the weeks around `date`.
    static func events(around date: Date, calendar: Calendar) -> [Event] {
        let today = calendar.startOfDay(for: date)
        var events: [Event] = []

        func add(
            _ title: String, day: Int, from start: Double, to end: Double, _ info: CalendarInfo, location: String? = nil
        ) {
            guard let dayStart = calendar.date(byAdding: .day, value: day, to: today) else { return }
            // Clock time, so events stay put on daylight-saving days.
            func at(_ hours: Double) -> Date {
                let minutes = Int((hours * 60).rounded())
                return calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: dayStart)
                    ?? dayStart
            }
            events.append(
                Event(
                    id: "\(title)-\(day)", title: title, location: location, start: at(start), end: at(end),
                    calendarID: info.id, color: info.color))
        }

        func addAllDay(_ title: String, day: Int, days: Int, _ info: CalendarInfo) {
            guard let start = calendar.date(byAdding: .day, value: day, to: today),
                let end = calendar.date(byAdding: .day, value: days, to: start)
            else { return }
            events.append(
                Event(
                    id: "\(title)-\(day)", title: title, start: start, end: end, isAllDay: true, calendarID: info.id,
                    color: info.color))
        }

        for week in -1...1 {
            let offset = week * 7
            add("Stand-up", day: offset - 2, from: 9.5, to: 9.75, work)
            add("Stand-up", day: offset - 1, from: 9.5, to: 9.75, work)
            add("Stand-up", day: offset, from: 9.5, to: 9.75, work)
            add("Stand-up", day: offset + 1, from: 9.5, to: 9.75, work)
            add("Stand-up", day: offset + 2, from: 9.5, to: 9.75, work)
            add("Design review", day: offset, from: 10, to: 11.5, work, location: "Room 4")
            add("Lunch with Sam", day: offset, from: 12, to: 13, home, location: "Café Nero")
            add("1:1", day: offset, from: 11, to: 11.5, work)
            add("Planning", day: offset + 1, from: 13, to: 15, work)
            add("Customer call", day: offset + 1, from: 14, to: 15, work)
            add("Gym", day: offset - 1, from: 7, to: 8, home)
            // Back to back, and a 15-minute event right before the next one.
            add("Check messages", day: offset + 1, from: 7, to: 7.5, home)
            add("Personal time", day: offset + 1, from: 7.5, to: 8.75, home)
            add("School drop-off", day: offset + 1, from: 8.75, to: 9, family)
            add("Design sync", day: offset + 1, from: 9, to: 10, work)
            add("Dentist", day: offset + 2, from: 15.5, to: 16.25, home, location: "Main Street 12")
            add("Football practice", day: offset + 3, from: 17, to: 18.5, family)
            add("Dinner party", day: offset + 4, from: 19, to: 22.5, family)
            add("Release", day: offset - 2, from: 16, to: 17, work)
        }
        addAllDay("Conference", day: 1, days: 2, work)
        addAllDay("Grandma's birthday", day: -1, days: 1, family)
        addAllDay("Holiday", day: 4, days: 1, home)
        return events
    }

    static func reminders(around date: Date, calendar: Calendar) -> [Reminder] {
        let today = calendar.startOfDay(for: date)
        func due(_ days: Int) -> Date? { calendar.date(byAdding: .day, value: days, to: today) }
        return [
            Reminder(
                id: "1", title: "Send the quarterly report", dueDate: due(0), priority: 1, calendarID: tasks.id,
                calendarTitle: tasks.title, color: tasks.color),
            Reminder(
                id: "2", title: "Book flights", dueDate: due(2), calendarID: tasks.id, calendarTitle: tasks.title,
                color: tasks.color),
            Reminder(id: "3", title: "Buy milk", calendarID: home.id, calendarTitle: home.title, color: home.color),
            Reminder(
                id: "4", title: "Renew passport", priority: 5, calendarID: home.id, calendarTitle: home.title,
                color: home.color),
            Reminder(
                id: "5", title: "Water the plants", calendarID: home.id, calendarTitle: home.title,
                color: home.color),
        ].sorted(by: Reminder.areInDisplayOrder)
    }
}
