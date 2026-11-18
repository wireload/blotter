import BlotterKit
import SwiftUI

/// The week: day titles, all-day events, and a time grid fitted to the day's events.
struct WeekView: View {
    let days: [Schedule.Day]
    let today: DateRange
    let now: Date
    let calendar: Calendar
    let allDayHeight: CGFloat
    let access: CalendarStore.Access

    @AppStorage(DefaultsKey.showsWeekdayDates) private var showsWeekdayDates = true

    static let columnSpacing: CGFloat = 6
    static let titleHeight: CGFloat = 32

    var body: some View {
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
            } else {
                TimeGrid(days: days, today: today, now: now, calendar: calendar)
            }
        }
    }

    private var titleFormat: Date.FormatStyle {
        showsWeekdayDates
            ? .dateTime.weekday(.abbreviated).day().month(.abbreviated)
            : .dateTime.weekday(.wide)
    }

    /// One cell per day, aligned with the time grid's columns.
    private func columns<Content: View>(@ViewBuilder content: @escaping (Schedule.Day) -> Content) -> some View {
        HStack(spacing: Self.columnSpacing) {
            Color.clear.frame(width: TimeRuler.width)
            ForEach(days) { day in
                content(day).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

/// All-day events of one day, stacked; whatever does not fit is summarised.
struct AllDayColumn: View {
    let events: [Event]

    static let rowHeight: CGFloat = 18
    static let rowSpacing: CGFloat = 3

    var body: some View {
        GeometryReader { geometry in
            let capacity = max(Int((geometry.size.height + Self.rowSpacing) / (Self.rowHeight + Self.rowSpacing)), 0)
            let overflows = events.count > capacity
            let shown = overflows ? max(capacity - 1, 0) : events.count

            VStack(spacing: Self.rowSpacing) {
                ForEach(events.prefix(shown)) { event in
                    EventBlock(event: event, isCompact: true)
                        .frame(height: Self.rowHeight)
                }
                if overflows, capacity > 0 {
                    Text("+\(events.count - shown) more")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(height: Self.rowHeight)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
        }
    }
}

/// Timed events of the week, with the time ruler and the current-time line.
struct TimeGrid: View {
    let days: [Schedule.Day]
    let today: DateRange
    let now: Date
    let calendar: Calendar

    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let fit = HourFit.fit(fitItems, height: height)
            let todayIndex = days.firstIndex { $0.range == today }

            HStack(spacing: WeekView.columnSpacing) {
                TimeRuler(fit: fit, height: height, day: today, calendar: calendar)
                ForEach(days) { day in
                    DayColumn(day: day, fit: fit, calendar: calendar, keepsTextVisible: false)
                }
            }
            .overlay(alignment: .topLeading) {
                if todayIndex != nil {
                    NowLine()
                        .padding(.leading, TimeRuler.width + WeekView.columnSpacing)
                        .offset(y: fit.offset(ofHour: Schedule.hour(of: now, on: today, calendar: calendar)))
                }
            }
        }
    }

    private var fitItems: [HourFit.Item] {
        days.flatMap { day in
            day.timed.map { entry in
                HourFit.Item(
                    startHour: Schedule.hour(of: entry.part.start, on: day.range, calendar: calendar),
                    endHour: Schedule.hour(of: entry.part.end, on: day.range, calendar: calendar),
                    minimumHeight: EventBlock.minimumHeight(for: entry.event))
            }
        }
    }
}

/// Hour labels next to the time grid.
struct TimeRuler: View {
    let fit: HourFit
    let height: CGFloat
    let day: DateRange
    let calendar: Calendar

    static let width: CGFloat = 40
    static let spacing: CGFloat = 6

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ForEach(visibleHours, id: \.self) { hour in
                Text(label(for: hour))
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.85))
                    .desktopTextShadow()
                    .frame(width: Self.width, height: 12, alignment: .trailing)
                    .offset(y: fit.offset(ofHour: Double(hour)) - 6)
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

    static let eventGap: CGFloat = 2

    var body: some View {
        GeometryReader { geometry in
            let placements = EventLayout.place(segments(height: geometry.size.height))
            let events = Dictionary(day.timed.map { ($0.event.id, $0.event) }, uniquingKeysWith: { first, _ in first })

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.10), .white.opacity(0.03)], startPoint: .top, endPoint: .bottom))

                ForEach(placements, id: \.segment.id) { placement in
                    if let event = events[placement.segment.id] {
                        let extent = placement.horizontalExtent(width: geometry.size.width, gap: Self.eventGap)
                        let top = CGFloat(placement.segment.top)
                        let visibleTop = keepsTextVisible ? max(top, 0) : top
                        EventBlock(event: event, isCompact: false, textInset: visibleTop - top)
                            .frame(width: extent.width, height: CGFloat(placement.segment.bottom) - top)
                            .offset(x: extent.x, y: top)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    /// Event extents in points, each at least tall enough for its title.
    private func segments(height: CGFloat) -> [EventLayout.Segment<String>] {
        day.timed.map { entry in
            let top = fit.offset(ofHour: Schedule.hour(of: entry.part.start, on: day.range, calendar: calendar))
            var bottom = fit.offset(ofHour: Schedule.hour(of: entry.part.end, on: day.range, calendar: calendar))
            bottom = max(bottom, top + EventBlock.minimumHeight(for: entry.event))
            return EventLayout.Segment(id: entry.event.id, top: Double(top), bottom: Double(bottom))
        }
    }
}

/// An event drawn in its calendar's colour.
struct EventBlock: View {
    let event: Event
    let isCompact: Bool
    var textInset: CGFloat = 0

    static func minimumHeight(for event: Event) -> CGFloat { 20 }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 4)
        VStack(alignment: .leading, spacing: 1) {
            Text(event.title)
                .font(.system(size: 10, weight: .medium))
            if !isCompact, let location = event.location {
                Text(location)
                    .font(.system(size: 10).italic())
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .lineLimit(isCompact ? 1 : nil)
        .desktopTextShadow()
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .padding(.top, textInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            shape.fill(Color(event.color).opacity(0.55))
            shape.fill(LinearGradient(colors: [.clear, .black.opacity(0.15)], startPoint: .top, endPoint: .bottom))
        }
        .overlay(shape.strokeBorder(.white.opacity(0.25), lineWidth: 1))
        .clipShape(shape)
        .accessibilityElement(children: .combine)
    }
}

/// The dashed current-time line.
struct NowLine: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: geometry.size.width, y: 0))
            }
            .stroke(.white.opacity(0.75), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: -1)
        }
        .frame(height: 1)
        .accessibilityHidden(true)
    }
}
