import BlotterKit
import SwiftUI

/// Everything inside the desktop window: the info column (date, To Do, Right Now) and the week.
struct CalendarView: View {
    @Environment(Clock.self) private var clock
    @Environment(CalendarStore.self) private var store
    @Environment(CalendarState.self) private var state

    @AppStorage(DefaultsKey.calendarLayout) private var layout = CalendarLayout.normal.rawValue
    @AppStorage(DefaultsKey.calendarSize) private var size = CalendarSize.normal.rawValue
    @AppStorage(DefaultsKey.infoWidth) private var infoWidth = 250.0
    @AppStorage(DefaultsKey.dateHeight) private var dateHeight = 250.0
    @AppStorage(DefaultsKey.toDoHeight) private var toDoHeight = 200.0
    @AppStorage(DefaultsKey.allDayHeight) private var allDayHeight = 110.0
    @AppStorage(DefaultsKey.showsNext7Days) private var showsNext7Days = false

    static let padding: CGFloat = 20

    private var days: [DateRange] {
        Schedule.days(
            containing: clock.now, weekOffset: state.weekOffset, rolling: showsNext7Days, calendar: clock.calendar)
    }

    private var today: DateRange {
        DateRange(clock.calendar.dateInterval(of: .day, for: clock.now) ?? DateInterval(start: clock.now, duration: 0))
    }

    /// Events are loaded for the visible week and today (for Right Now).
    private var loadedRange: DateRange {
        days.reduce(today) { $0.union($1) }
    }

    var body: some View {
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
                            DateView(date: clock.now)
                                .frame(height: panes.dateHeight)
                        }
                        if panes.toDoHeight > 0 {
                            ToDoView(reminders: store.reminders, access: store.reminderAccess)
                                .frame(height: panes.toDoHeight)
                        }
                        if panes.rightNowHeight > 0 {
                            RightNowView(day: today, events: store.events, now: clock.now, calendar: clock.calendar)
                                .frame(height: panes.rightNowHeight)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(width: panes.infoWidth)
                }
                if panes.showsWeek {
                    WeekView(
                        days: Schedule.arrange(store.events, into: days),
                        today: today,
                        now: clock.now,
                        calendar: clock.calendar,
                        allDayHeight: panes.allDayHeight,
                        access: store.eventAccess
                    )
                    .id(days.first?.start)
                    .transition(weekTransition)
                    .frame(width: panes.weekWidth)
                }
            }
            .padding(Self.padding)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
            .clipped()
        }
        .foregroundStyle(.white)
        .environment(\.colorScheme, .dark)
        .animation(.easeInOut(duration: 0.25), value: state.weekOffset)
        .onChange(of: loadedRange, initial: true) { _, range in
            store.visibleRange = range
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

    private var weekTransition: AnyTransition {
        .push(from: state.lastNavigationWasForward ? .trailing : .leading)
    }
}

/// Shared styling for text drawn over the desktop.
extension View {
    func desktopTextShadow() -> some View {
        shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
    }
}

extension Color {
    init(_ color: RGBAColor) {
        self.init(.sRGB, red: color.red, green: color.green, blue: color.blue, opacity: color.alpha)
    }
}

/// A titled, softly outlined box, used for To Do and Right Now.
struct Box<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 26, weight: .light))
                .lineLimit(1)
                .desktopTextShadow()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(EdgeInsets(top: 12, leading: 15, bottom: 15, trailing: 13))
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.white.opacity(0.12)))
    }
}
