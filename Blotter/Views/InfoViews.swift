import BlotterKit
import SwiftUI

/// Today's date, like Calendar's date widget: the weekday in red capitals over a large day number.
struct DateView: View {
    let date: Date

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let theme = Theme(colorScheme: colorScheme)
        VStack(alignment: .leading, spacing: 0) {
            Text(date.formatted(.dateTime.weekday(.wide)).localizedUppercase)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.opacity)
            Text(date, format: .dateTime.day())
                .font(.system(size: 160, weight: .light))
                .minimumScaleFactor(0.25)
                .lineLimit(1)
                .contentTransition(.numericText(countsDown: false))
                .frame(maxHeight: .infinity, alignment: .leading)
            Text(date, format: .dateTime.month(.wide).year())
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(theme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .animation(reduceMotion ? nil : .smooth(duration: 0.6), value: date)
        .accessibilityElement(children: .combine)
    }
}

/// Incomplete reminders, styled like the Reminders widget.
struct ToDoView: View {
    let reminders: [Reminder]
    let access: CalendarStore.Access

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let rowHeight: CGFloat = 20
    static let rowSpacing: CGFloat = 8

    var body: some View {
        Card(title: "To Do") {
            switch access {
            case .denied:
                AccessHint(text: "Allow Blotter to access Reminders in System Settings.")
            case .notDetermined:
                EmptyView()
            case .granted:
                GeometryReader { geometry in
                    let fitting = max(
                        Int((geometry.size.height + Self.rowSpacing) / (Self.rowHeight + Self.rowSpacing)), 0)
                    let overflows = reminders.count > fitting
                    let shown = overflows ? max(fitting - 1, 0) : reminders.count
                    VStack(alignment: .leading, spacing: Self.rowSpacing) {
                        ForEach(reminders.prefix(shown)) { reminder in
                            ReminderRow(reminder: reminder)
                                .transition(
                                    .asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .leading)),
                                        removal: .opacity))
                        }
                        if overflows, fitting > 0 {
                            Text("+\(reminders.count - shown) more")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme(colorScheme: colorScheme).secondaryText)
                                .frame(height: Self.rowHeight)
                        }
                    }
                    .animation(Motion.update(reduceMotion: reduceMotion), value: reminders)
                }
            }
        }
    }
}

/// A reminder with the list's coloured ring, as in Reminders.
private struct ReminderRow: View {
    let reminder: Reminder

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .strokeBorder(Color(reminder.color), lineWidth: 1.5)
                .frame(width: 13, height: 13)
            Text(reminder.title)
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(height: ToDoView.rowHeight)
    }
}

/// Today, centred on the current hour.
struct RightNowView: View {
    let day: DateRange
    let events: [Event]
    let calendar: Calendar

    var body: some View {
        Card(title: "Right Now") {
            GeometryReader { geometry in
                RightNowTimeline(day: day, events: events, calendar: calendar, height: geometry.size.height)
            }
        }
    }
}

/// The scrolling part of Right Now. It is the only part of the card that depends on the current minute.
private struct RightNowTimeline: View {
    let day: DateRange
    let events: [Event]
    let calendar: Calendar
    let height: CGFloat

    @Environment(Clock.self) private var clock
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let hourHeight = max(40, (height / 24).rounded())
        let visibleHours = Double(height / hourHeight)
        let nowHour = Schedule.hour(of: clock.now, on: day, calendar: calendar)
        let start = min(max(nowHour - visibleHours / 2, 0), max(24 - visibleHours, 0))
        let fit = HourFit(startHour: start, hourHeight: hourHeight)
        let schedule = Schedule.arrange(events, into: [day])[0]

        HStack(spacing: TimeRuler.spacing) {
            TimeRuler(fit: fit, height: height, day: day, calendar: calendar)
            DayColumn(day: schedule, fit: fit, calendar: calendar, keepsTextVisible: true)
        }
        .overlay(alignment: .topLeading) {
            NowLine()
                .padding(.leading, TimeRuler.width + TimeRuler.spacing)
                .offset(y: fit.offset(ofHour: nowHour))
        }
        .animation(reduceMotion ? nil : .smooth(duration: 0.8), value: start)
        .mask {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: DayColumn.pinnedTitleInset),
                    .init(color: .black, location: 1 - DayColumn.pinnedTitleInset),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .top, endPoint: .bottom)
        }
    }
}

/// Shown in place of content when calendar or reminder access was refused.
struct AccessHint: View {
    let text: LocalizedStringKey

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(Theme(colorScheme: colorScheme).secondaryText)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .multilineTextAlignment(.center)
    }
}
