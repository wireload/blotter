import BlotterKit
import SwiftUI

/// Everything inside the desktop window: the info column (date, To Do, Right Now) and the week.
struct CalendarView: View {
    @Environment(Clock.self) private var clock
    @Environment(CalendarStore.self) private var store
    @Environment(CalendarState.self) private var state
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage(DefaultsKey.calendarLayout) private var layout = CalendarLayout.normal.rawValue
    @AppStorage(DefaultsKey.calendarSize) private var size = CalendarSize.normal.rawValue
    @AppStorage(DefaultsKey.infoWidth) private var infoWidth = 250.0
    @AppStorage(DefaultsKey.dateHeight) private var dateHeight = 250.0
    @AppStorage(DefaultsKey.toDoHeight) private var toDoHeight = 200.0
    @AppStorage(DefaultsKey.allDayHeight) private var allDayHeight = 110.0
    @AppStorage(DefaultsKey.showsNext7Days) private var showsNext7Days = false

    static let padding: CGFloat = 20
    static let cornerRadius: CGFloat = 12

    // Everything here derives from `clock.today`, not `clock.now`, so the calendar is not rebuilt every minute.
    private var days: [DateRange] {
        Schedule.days(
            containing: clock.today, weekOffset: state.weekOffset, rolling: showsNext7Days, calendar: clock.calendar)
    }

    private var today: DateRange {
        DateRange(
            clock.calendar.dateInterval(of: .day, for: clock.today) ?? DateInterval(start: clock.today, duration: 0))
    }

    /// Events are loaded for the visible week and today (for Right Now), without the weeks in between.
    private var loadedRanges: [DateRange] {
        guard let first = days.first, let last = days.last else { return [today] }
        let week = first.union(last)
        return week.intersects(today) || week.end == today.start || today.end == week.start
            ? [week.union(today)] : [week, today]
    }

    var body: some View {
        let theme = Theme(colorScheme: colorScheme)
        let schedule = Schedule.arrange(store.events, into: days)

        GeometryReader { geometry in
            let inner = CGSize(
                width: max(geometry.size.width - Self.padding * 2, 0),
                height: max(geometry.size.height - Self.padding * 2, 0))
            let panes = PaneLayout(
                size: inner,
                layout: CalendarLayout(rawValue: layout) ?? .normal,
                calendarSize: CalendarSize(rawValue: size) ?? .normal,
                metrics: metrics)

            HStack(alignment: .top, spacing: PaneLayout.spacingAfterInfo) {
                if panes.showsInfo {
                    VStack(spacing: PaneLayout.spacingAfterDate) {
                        if panes.dateHeight > 0 {
                            Card { DateView(date: clock.today) }
                                .frame(height: panes.dateHeight)
                        }
                        if panes.toDoHeight > 0 {
                            ToDoView(reminders: store.reminders, access: store.reminderAccess)
                                .frame(height: panes.toDoHeight)
                        }
                        if panes.rightNowHeight > 0 {
                            RightNowView(day: today, events: store.events, calendar: clock.calendar)
                                .frame(height: panes.rightNowHeight)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(width: panes.infoWidth)
                }
                if panes.showsWeek {
                    Card {
                        WeekView(
                            days: schedule,
                            today: today,
                            calendar: clock.calendar,
                            allDayHeight: panes.allDayHeight,
                            access: store.eventAccess,
                            weekOffset: state.weekOffset,
                            navigatesForward: state.lastNavigationWasForward
                        )
                    }
                    .frame(width: panes.weekWidth)
                }
            }
            .padding(Self.padding)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
            .clipped()
        }
        .foregroundStyle(theme.text)
        .background {
            // On the desktop each pane is its own card; in front, the whole window gets a backdrop.
            if state.presentation == .front {
                RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                    .fill(theme.frontBackground)
            }
        }
        .animation(Motion.navigation(reduceMotion: reduceMotion), value: state.weekOffset)
        .onChange(of: loadedRanges, initial: true) { _, ranges in
            store.visibleRanges = ranges
        }
    }

    private var metrics: PaneLayout.Metrics {
        var metrics = PaneLayout.Metrics()
        metrics.infoWidth = infoWidth
        metrics.dateHeight = dateHeight
        metrics.toDoHeight = toDoHeight
        metrics.allDayHeight = allDayHeight
        return metrics
    }
}
