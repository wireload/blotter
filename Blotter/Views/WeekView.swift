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

    /// Days sit edge to edge, separated by hairlines, as in Calendar.
    static let columnSpacing: CGFloat = 0
    static let titleHeight = PaneLayout.Metrics().weekTitleHeight

    var body: some View {
        GeometryReader { geometry in
            let allDayBlock = allDayHeight > 0 ? allDayHeight + PaneLayout.spacingAfterAllDay : 0
            let timedHeight = max(geometry.size.height - Self.titleHeight - allDayBlock, 0)
            let fit = HourFit.fit(fitItems, height: timedHeight)

            HStack(alignment: .top, spacing: TimeRuler.spacing) {
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
                DayHeader(date: day.range.start, isToday: day.range == today, showsDate: showsWeekdayDates)
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
                    if let todayIndex = days.firstIndex(where: { $0.range == today }) {
                        CurrentTimeLine(
                            today: today, fit: fit, calendar: calendar, height: timedHeight,
                            todayIndex: todayIndex, dayCount: days.count)
                    }
                }
                .clipped()
            }
        }
    }

    private var transition: AnyTransition {
        reduceMotion ? .opacity : .push(from: navigatesForward ? .trailing : .leading)
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

/// A day's title, as in Calendar's week view: the weekday in small capitals over the day number, today's number in a
/// red circle.
private struct DayHeader: View {
    let date: Date
    let isToday: Bool
    let showsDate: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = Theme(colorScheme: colorScheme)
        if showsDate {
            VStack(spacing: 3) {
                Text(date.formatted(.dateTime.weekday(.abbreviated)).localizedUppercase)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isToday ? theme.accent : theme.secondaryText)
                Text(date, format: .dateTime.day())
                    .font(.system(size: 15, weight: isToday ? .semibold : .regular))
                    .monospacedDigit()
                    .foregroundStyle(isToday ? .white : theme.text)
                    .frame(width: 26, height: 26)
                    .background {
                        if isToday {
                            Circle().fill(theme.accent)
                        }
                    }
            }
            .lineLimit(1)
            .accessibilityElement(children: .combine)
        } else {
            Text(date, format: .dateTime.weekday(.wide))
                .font(.system(size: 12, weight: isToday ? .semibold : .medium))
                .foregroundStyle(isToday ? theme.accent : theme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

/// The current-time line: faint across the week, solid red across today with a dot at its start, as in Calendar.
/// It reads the clock itself, so minute ticks only redraw the line.
private struct CurrentTimeLine: View {
    let today: DateRange
    let fit: HourFit
    let calendar: Calendar
    let height: CGFloat
    let todayIndex: Int
    let dayCount: Int

    @Environment(Clock.self) private var clock
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let y = fit.offset(ofHour: Schedule.hour(of: clock.now, on: today, calendar: calendar))
        let accent = Theme(colorScheme: colorScheme).accent
        // Outside the visible hours (before the first or after the last), there is no line to draw.
        if y >= 0, y <= height {
            GeometryReader { geometry in
                let dayWidth = geometry.size.width / CGFloat(max(dayCount, 1))
                let x = dayWidth * CGFloat(todayIndex)
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(accent.opacity(0.35))
                        .frame(height: 1)
                    Rectangle()
                        .fill(accent)
                        .frame(width: dayWidth, height: 1.5)
                        .offset(x: x)
                    Circle()
                        .fill(accent)
                        .frame(width: 7, height: 7)
                        .offset(x: x - 3.5, y: -2.75)
                }
                .offset(y: y)
            }
            .frame(height: height)
            .animation(reduceMotion ? nil : .smooth(duration: 0.8), value: y)
            .accessibilityHidden(true)
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
                    EventBlock(event: event, style: .allDay)
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
            .padding(.horizontal, 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
    static let spacing: CGFloat = 8

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ForEach(visibleHours, id: \.self) { hour in
                Text(label(for: hour))
                    .font(.system(size: 10, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(Theme(colorScheme: colorScheme).secondaryText)
                    .frame(width: Self.width, height: 12, alignment: .trailing)
                    .offset(y: fit.offset(ofHour: Double(hour)) - 6)
                    .transition(.opacity)
            }
        }
        .frame(width: Self.width, height: height, alignment: .topTrailing)
        // Events carry their own times for VoiceOver; the ruler would only add noise.
        .accessibilityHidden(true)
    }

    /// Whole hours whose label fits entirely inside the grid.
    private var visibleHours: [Int] {
        (0...24).filter { hour in
            let y = fit.offset(ofHour: Double(hour))
            return y >= 6 && y <= height - 6
        }
    }

    /// Formats the hour on a fixed day without daylight-saving changes, so a skipped hour (02:00 on the
    /// spring-forward day) is still labelled correctly instead of repeating the next one.
    private func label(for hour: Int) -> String {
        var reference = Calendar(identifier: .gregorian)
        reference.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let date =
            reference.date(from: DateComponents(year: 2001, month: 1, day: 1, hour: hour % 24)) ?? day.start
        var style = Date.FormatStyle.dateTime.hour()
        style.timeZone = reference.timeZone
        style.locale = calendar.locale ?? .current
        return date.formatted(style)
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
    /// Space between events and the day's edges.
    static let inset: CGFloat = 2
    /// Space above and below each event, so events that end and start at the same time stay distinct.
    static let verticalGap: CGFloat = 1
    /// Fraction of the column hidden by Right Now's fade at the top.
    static let pinnedTitleInset: CGFloat = 0.08

    var body: some View {
        GeometryReader { geometry in
            // Beyond one column per 12 points, events would be unreadable slivers; extra ones share columns.
            let placements = EventLayout.place(segments, maximumColumns: max(Int(geometry.size.width / 14), 1))
            let events = Dictionary(day.timed.map { ($0.event.id, $0.event) }, uniquingKeysWith: { first, _ in first })

            let theme = Theme(colorScheme: colorScheme)
            let eventWidth = max(geometry.size.width - Self.inset * 2, 0)

            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(calendar.isDateInWeekend(day.range.start) ? theme.weekendFill : .clear)
                HourGrid(fit: fit, height: geometry.size.height)
                    .stroke(theme.gridLine, lineWidth: 0.5)
                Rectangle()
                    .fill(theme.gridLine)
                    .frame(width: 0.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

                ForEach(placements, id: \.segment.id) { placement in
                    if let event = events[placement.segment.id] {
                        let extent = placement.horizontalExtent(width: eventWidth, gap: Self.eventGap)
                        let top = CGFloat(placement.segment.top)
                        // Short events are drawn tall enough for a line of text, even if that covers the start of
                        // the next one; the next one is drawn on top, as in Calendar.
                        let bottom = max(CGFloat(placement.segment.bottom), top + EventBlock.minimumHeight)
                        let height = bottom - top
                        // In Right Now, keep the title of an ongoing event below the fade at the top.
                        let pinned = geometry.size.height * DayColumn.pinnedTitleInset
                        let visibleTop =
                            keepsTextVisible ? max(top, min(pinned, bottom - EventBlock.minimumHeight)) : top
                        EventBlock(
                            event: event,
                            style: height - (visibleTop - top) < EventBlock.twoLineHeight ? .oneLine : .full,
                            textInset: visibleTop - top
                        )
                        // A point of space above and below keeps back-to-back events apart.
                        .frame(width: extent.width, height: max(height - Self.verticalGap * 2, 1))
                        .offset(x: extent.x + Self.inset, y: top + Self.verticalGap)
                        .zIndex(Double(top))
                        .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
                    }
                }
            }
            .clipped()
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text(day.range.start, format: .dateTime.weekday(.wide).day().month(.wide)))
            .animation(Motion.update(reduceMotion: reduceMotion), value: placements)
        }
    }

    /// Event extents in points, from their real start and end times.
    ///
    /// Overlaps are decided on real times: a 15-minute event that ends as the next one starts is not an overlap, even
    /// though it is drawn taller than 15 minutes to fit its title. Otherwise both would be squeezed side by side.
    private var segments: [EventLayout.Segment<String>] {
        day.timed.map { entry in
            let top = fit.offset(ofHour: Schedule.hour(of: entry.part.start, on: day.range, calendar: calendar))
            let bottom = fit.offset(ofHour: Schedule.hour(of: entry.part.end, on: day.range, calendar: calendar))
            return EventLayout.Segment(id: entry.event.id, top: Double(top), bottom: Double(max(bottom, top + 1)))
        }
    }
}

/// An event drawn in its calendar's colour, with a solid bar along its leading edge.
struct EventBlock: View {
    enum Style {
        /// Title, time and location, on separate lines.
        case full
        /// Title and time on one line, for short events.
        case oneLine
        /// Title only, for all-day events.
        case allDay
    }

    let event: Event
    let style: Style
    var textInset: CGFloat = 0

    @Environment(\.colorScheme) private var colorScheme

    /// Tall enough for one line of text.
    static let minimumHeight: CGFloat = 20
    /// Below this height, title and time share one line.
    static let twoLineHeight: CGFloat = 32

    /// Title, time and location, for VoiceOver.
    private var accessibilityDescription: String {
        var parts = [event.title]
        parts.append(
            event.isAllDay
                ? String(localized: "All day") : (event.start..<event.end).formatted(.interval.hour().minute()))
        if let location = event.location {
            parts.append(location)
        }
        return parts.joined(separator: ", ")
    }

    private var time: some View {
        Text(event.start, format: .dateTime.hour().minute())
            .font(.system(size: 10))
            .monospacedDigit()
            .opacity(0.8)
            .lineLimit(1)
    }

    var body: some View {
        let theme = Theme(colorScheme: colorScheme)
        let shape = RoundedRectangle(cornerRadius: 5, style: .continuous)
        let textColor = theme.eventText(event.color)

        Group {
            switch style {
            case .full:
                VStack(alignment: .leading, spacing: 1) {
                    Text(event.title)
                        .font(.system(size: 11, weight: .semibold))
                    time
                    if let location = event.location {
                        Text(location)
                            .font(.system(size: 10))
                            .opacity(0.8)
                    }
                }
            case .oneLine:
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(event.title)
                        .font(.system(size: 11, weight: .semibold))
                        .layoutPriority(1)
                    time
                }
                .lineLimit(1)
            case .allDay:
                Text(event.title)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
            }
        }
        .foregroundStyle(textColor)
        .padding(.leading, 8)
        .padding(.trailing, 4)
        .padding(.vertical, style == .full ? 3 : 2)
        .padding(.top, textInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            shape.fill(theme.eventFill(event.color))
            Rectangle()
                .fill(Color(event.color))
                .frame(width: 3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .clipShape(shape)
        // A hairline edge separates an event from one drawn over it.
        .overlay(shape.strokeBorder(theme.eventEdge, lineWidth: 0.5))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }
}

/// Hairlines at every whole hour, as in Calendar's day and week views.
private nonisolated struct HourGrid: Shape {
    let fit: HourFit
    let height: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for hour in 0...24 {
            let y = fit.offset(ofHour: Double(hour))
            guard y > 0, y < height else { continue }
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        return path
    }
}

/// The current-time line in Right Now: red, with a dot at its start.
struct NowLine: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let accent = Theme(colorScheme: colorScheme).accent
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(accent)
                .frame(height: 1.5)
            Circle()
                .fill(accent)
                .frame(width: 7, height: 7)
                .offset(x: -3.5)
        }
        .frame(height: 7)
        .offset(y: -3.5)
        .accessibilityHidden(true)
    }
}
