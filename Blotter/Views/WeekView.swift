import BlotterKit
import SwiftUI

/// The week: day titles, all-day events, and a time grid fitted to the week's events.
///
/// The time ruler stays in place while the days slide in from the side when navigating between weeks; the hour scale
/// animates to fit the new week's events.
struct WeekView: View {
    let days: [Schedule.Day]
    let today: DateRange
    let calendar: Calendar
    let allDayHeight: CGFloat
    let access: CalendarStore.Access
    let weekOffset: Int
    let navigatesForward: Bool

    @AppStorage(DefaultsKey.showsWeekdayDates) private var showsWeekdayDates = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let columnSpacing: CGFloat = 6
    static let titleHeight: CGFloat = 32

    var body: some View {
        GeometryReader { geometry in
            let allDayBlock = allDayHeight > 0 ? allDayHeight + PaneLayout.spacingAfterAllDay : 0
            let timedHeight = max(geometry.size.height - Self.titleHeight - allDayBlock, 0)
            let fit = HourFit.fit(fitItems, height: timedHeight)

            HStack(alignment: .top, spacing: Self.columnSpacing) {
                TimeRuler(fit: fit, height: timedHeight, day: today, calendar: calendar)
                    .padding(.top, Self.titleHeight + allDayBlock)

                ZStack {
                    weekDays(fit: fit, timedHeight: timedHeight, allDayBlock: allDayBlock)
                        .id(weekOffset)
                        .transition(transition)
                }
                .clipped()
            }
        }
    }

    private func weekDays(fit: HourFit, timedHeight: CGFloat, allDayBlock: CGFloat) -> some View {
        VStack(spacing: 0) {
            columns { day in
                Text(day.range.start, format: titleFormat)
                    .font(.system(size: 11, weight: day.range == today ? .bold : .regular))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .desktopTextShadow()
            }
            .frame(height: Self.titleHeight)

            if allDayHeight > 0 {
                columns { day in
                    AllDayColumn(events: day.allDay)
                }
                .frame(height: allDayHeight)
                .padding(.bottom, PaneLayout.spacingAfterAllDay)
            }

            if access == .denied {
                AccessHint(text: "Allow Blotter to access your calendars in System Settings › Privacy & Security.")
                    .frame(height: timedHeight)
            } else {
                columns { day in
                    DayColumn(day: day, fit: fit, calendar: calendar, keepsTextVisible: false)
                }
                .frame(height: timedHeight)
                .overlay(alignment: .topLeading) {
                    if days.contains(where: { $0.range == today }) {
                        CurrentTimeLine(today: today, fit: fit, calendar: calendar, height: timedHeight)
                    }
                }
                .clipped()
            }
        }
    }

    private var transition: AnyTransition {
        reduceMotion ? .opacity : .push(from: navigatesForward ? .trailing : .leading)
    }

    private var titleFormat: Date.FormatStyle {
        showsWeekdayDates
            ? .dateTime.weekday(.abbreviated).day().month(.abbreviated)
            : .dateTime.weekday(.wide)
    }

    /// One cell per day.
    private func columns<Content: View>(@ViewBuilder content: @escaping (Schedule.Day) -> Content) -> some View {
        HStack(spacing: Self.columnSpacing) {
            ForEach(days) { day in
                content(day).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var fitItems: [HourFit.Item] {
        days.flatMap { day in
            day.timed.map { entry in
                HourFit.Item(
                    startHour: Schedule.hour(of: entry.part.start, on: day.range, calendar: calendar),
                    endHour: Schedule.hour(of: entry.part.end, on: day.range, calendar: calendar),
                    minimumHeight: EventBlock.minimumHeight)
            }
        }
    }
}

/// The current-time line across the week. It reads the clock itself, so minute ticks only redraw the line.
private struct CurrentTimeLine: View {
    let today: DateRange
    let fit: HourFit
    let calendar: Calendar
    let height: CGFloat

    @Environment(Clock.self) private var clock
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let y = fit.offset(ofHour: Schedule.hour(of: clock.now, on: today, calendar: calendar))
        // Outside the visible hours (before the first or after the last), there is no line to draw.
        if y >= 0, y <= height {
            NowLine()
                .offset(y: y)
                .animation(reduceMotion ? nil : .smooth(duration: 0.8), value: y)
        }
    }
}

/// All-day events of one day, stacked; whatever does not fit is summarised.
struct AllDayColumn: View {
    let events: [Event]

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let rowHeight: CGFloat = 18
    static let rowSpacing: CGFloat = 3

    var body: some View {
        let theme = Theme(colorScheme: colorScheme)
        GeometryReader { geometry in
            let capacity = max(Int((geometry.size.height + Self.rowSpacing) / (Self.rowHeight + Self.rowSpacing)), 0)
            let overflows = events.count > capacity
            let shown = overflows ? max(capacity - 1, 0) : events.count

            VStack(spacing: Self.rowSpacing) {
                ForEach(events.prefix(shown)) { event in
                    EventBlock(event: event, isCompact: true)
                        .frame(height: Self.rowHeight)
                        .transition(.opacity)
                }
                if overflows, capacity > 0 {
                    Text("+\(events.count - shown) more")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(theme.secondaryText)
                        .frame(height: Self.rowHeight)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(theme.panelFill, in: RoundedRectangle(cornerRadius: 6))
            .animation(Motion.update(reduceMotion: reduceMotion), value: events)
        }
    }
}

/// Hour labels next to the time grid.
struct TimeRuler: View {
    let fit: HourFit
    let height: CGFloat
    let day: DateRange
    let calendar: Calendar

    @Environment(\.colorScheme) private var colorScheme

    static let width: CGFloat = 40
    static let spacing: CGFloat = 6

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ForEach(visibleHours, id: \.self) { hour in
                Text(label(for: hour))
                    .font(.system(size: 10))
                    .foregroundStyle(Theme(colorScheme: colorScheme).secondaryText)
                    .desktopTextShadow()
                    .frame(width: Self.width, height: 12, alignment: .trailing)
                    .offset(y: fit.offset(ofHour: Double(hour)) - 6)
                    .transition(.opacity)
            }
        }
        .frame(width: Self.width, height: height, alignment: .topTrailing)
    }

    /// Whole hours whose label fits entirely inside the grid.
    private var visibleHours: [Int] {
        (0...24).filter { hour in
            let y = fit.offset(ofHour: Double(hour))
            return y >= 6 && y <= height - 6
        }
    }

    private func label(for hour: Int) -> String {
        let date = calendar.date(bySettingHour: hour % 24, minute: 0, second: 0, of: day.start) ?? day.start
        return date.formatted(.dateTime.hour())
    }
}

/// One day's timed events, arranged side by side where they overlap.
struct DayColumn: View {
    let day: Schedule.Day
    let fit: HourFit
    let calendar: Calendar
    /// Keeps the title of an event that starts above the visible area in view.
    let keepsTextVisible: Bool

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let eventGap: CGFloat = 2

    var body: some View {
        GeometryReader { geometry in
            let placements = EventLayout.place(segments)
            let events = Dictionary(day.timed.map { ($0.event.id, $0.event) }, uniquingKeysWith: { first, _ in first })

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme(colorScheme: colorScheme).columnFill)

                ForEach(placements, id: \.segment.id) { placement in
                    if let event = events[placement.segment.id] {
                        let extent = placement.horizontalExtent(width: geometry.size.width, gap: Self.eventGap)
                        let top = CGFloat(placement.segment.top)
                        let visibleTop = keepsTextVisible ? max(top, 0) : top
                        EventBlock(event: event, isCompact: false, textInset: visibleTop - top)
                            .frame(width: extent.width, height: CGFloat(placement.segment.bottom) - top)
                            .offset(x: extent.x, y: top)
                            .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .animation(Motion.update(reduceMotion: reduceMotion), value: placements)
        }
    }

    /// Event extents in points, each at least tall enough for its title.
    private var segments: [EventLayout.Segment<String>] {
        day.timed.map { entry in
            let top = fit.offset(ofHour: Schedule.hour(of: entry.part.start, on: day.range, calendar: calendar))
            var bottom = fit.offset(ofHour: Schedule.hour(of: entry.part.end, on: day.range, calendar: calendar))
            bottom = max(bottom, top + EventBlock.minimumHeight)
            return EventLayout.Segment(id: entry.event.id, top: Double(top), bottom: Double(bottom))
        }
    }
}

/// An event drawn in its calendar's colour, with a solid bar along its leading edge.
struct EventBlock: View {
    let event: Event
    let isCompact: Bool
    var textInset: CGFloat = 0

    @Environment(\.colorScheme) private var colorScheme

    static let minimumHeight: CGFloat = 20

    var body: some View {
        let theme = Theme(colorScheme: colorScheme)
        let shape = RoundedRectangle(cornerRadius: 4)

        VStack(alignment: .leading, spacing: 1) {
            Text(event.title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(theme.eventText)
            if !isCompact, let location = event.location {
                Text(location)
                    .font(.system(size: 10).italic())
                    .foregroundStyle(theme.eventSecondaryText)
            }
        }
        .lineLimit(isCompact ? 1 : nil)
        .padding(.leading, 7)
        .padding(.trailing, 4)
        .padding(.vertical, 3)
        .padding(.top, textInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            shape.fill(theme.eventFill(event.color))
            Rectangle()
                .fill(Color(event.color))
                .frame(width: 3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .overlay(shape.strokeBorder(theme.eventStroke, lineWidth: 1))
        .clipShape(shape)
        .accessibilityElement(children: .combine)
    }
}

/// The dashed current-time line.
struct NowLine: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: geometry.size.width, y: 0))
            }
            .stroke(Theme(colorScheme: colorScheme).nowLine, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
        }
        .frame(height: 1)
        .accessibilityHidden(true)
    }
}
