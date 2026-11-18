import Foundation
import Testing

@testable import BlotterKit

@Suite struct ScheduleTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Stockholm")!
        calendar.firstWeekday = 2
        return calendar
    }()

    func date(_ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    @Test func calendarWeekStartsOnFirstWeekday() {
        // Wednesday 18 November 2026.
        let days = Schedule.days(containing: date(18, 15), rolling: false, calendar: calendar)
        #expect(days.count == 7)
        #expect(days.first!.start == date(16))
        #expect(days.last!.end == date(23))
    }

    @Test func weekOffset() {
        let days = Schedule.days(containing: date(18, 15), weekOffset: -1, rolling: false, calendar: calendar)
        #expect(days.first!.start == date(9))
    }

    @Test func rollingWeekStartsToday() {
        let days = Schedule.days(containing: date(18, 15), weekOffset: 1, rolling: true, calendar: calendar)
        #expect(days.first!.start == date(25))
        #expect(days.count == 7)
    }

    @Test func weekAcrossDaylightSavingChange() {
        // Sweden leaves DST on Sunday 25 October 2026; that day is 25 hours long.
        let days = Schedule.days(
            containing: date(25).addingTimeInterval(-86_400 * 23), rolling: false, calendar: calendar)
        #expect(days.count == 7)
    }

    @Test func arrangesEvents() {
        let days = [DateRange(start: date(18), end: date(19)), DateRange(start: date(19), end: date(20))]
        let events = [
            Event(id: "meeting", title: "Meeting", start: date(18, 10), end: date(18, 11), calendarID: "work"),
            Event(id: "overnight", title: "Flight", start: date(18, 22), end: date(19, 6), calendarID: "travel"),
            Event(id: "holiday", title: "Holiday", start: date(18), end: date(20), isAllDay: true, calendarID: "home"),
            Event(
                id: "birthday", title: "Birthday", start: date(19), end: date(20), isAllDay: true, calendarID: "home"),
        ]

        let arranged = Schedule.arrange(events, into: days)

        #expect(arranged[0].timed.map(\.event.id) == ["meeting", "overnight"])
        #expect(arranged[0].timed[1].part == DateRange(start: date(18, 22), end: date(19)))
        #expect(arranged[0].allDay.map(\.id) == ["holiday"])

        #expect(arranged[1].timed.map(\.event.id) == ["overnight"])
        #expect(arranged[1].timed[0].part == DateRange(start: date(19), end: date(19, 6)))
        // Longest first.
        #expect(arranged[1].allDay.map(\.id) == ["holiday", "birthday"])
    }

    @Test func hourOfDay() {
        let day = DateRange(start: date(18), end: date(19))
        #expect(Schedule.hour(of: date(18, 13, 30), on: day, calendar: calendar) == 13.5)
        #expect(Schedule.hour(of: date(17, 23), on: day, calendar: calendar) == 0)
        #expect(Schedule.hour(of: date(19), on: day, calendar: calendar) == 24)
    }

    @Test func reminderOrder() {
        let reminders = [
            Reminder(id: "1", title: "Undated low", priority: 9, calendarID: "a"),
            Reminder(id: "2", title: "Undated none", calendarID: "a"),
            Reminder(id: "3", title: "Later", dueDate: date(20), calendarID: "a"),
            Reminder(id: "4", title: "Sooner", dueDate: date(19), calendarID: "a"),
            Reminder(id: "5", title: "Undated high", priority: 1, calendarID: "a"),
        ]
        let sorted = reminders.sorted(by: Reminder.areInDisplayOrder).map(\.id)
        #expect(sorted == ["4", "3", "5", "1", "2"])
    }
}
