import BlotterKit
import SwiftUI

/// Today's date, large.
struct DateView: View {
    let date: Date

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            Text(date, format: .dateTime.day())
                .font(.system(size: 200, weight: .ultraLight))
                .minimumScaleFactor(0.3)
                .lineLimit(1)
                .contentTransition(.numericText(countsDown: false))
            Text(date, format: .dateTime.month(.wide).year())
                .font(.system(size: 26, weight: .light))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.opacity)
            Text(date, format: .dateTime.weekday(.wide))
                .font(.system(size: 26, weight: .light))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .desktopTextShadow()
        .animation(reduceMotion ? nil : .smooth(duration: 0.6), value: date)
        .accessibilityElement(children: .combine)
    }
}

/// Incomplete reminders.
struct ToDoView: View {
    let reminders: [Reminder]
    let access: CalendarStore.Access

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let rowHeight: CGFloat = 20
    static let rowSpacing: CGFloat = 9

    var body: some View {
        Box(title: "To Do") {
            switch access {
            case .denied:
                AccessHint(text: "Allow Blotter to access Reminders in System Settings.")
            case .notDetermined:
                EmptyView()
            case .granted:
                GeometryReader { geometry in
                    let fitting = Int((geometry.size.height + Self.rowSpacing) / (Self.rowHeight + Self.rowSpacing))
                    VStack(alignment: .leading, spacing: Self.rowSpacing) {
                        ForEach(reminders.prefix(max(fitting, 0))) { reminder in
                            ReminderRow(reminder: reminder)
                                .transition(
                                    .asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .leading)),
                                        removal: .opacity))
                        }
                    }
                    .animation(Motion.update(reduceMotion: reduceMotion), value: reminders)
                }
            }
        }
    }
}

private struct ReminderRow: View {
    let reminder: Reminder

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(reminder.color))
                .frame(width: 8, height: 8)
            Text(reminder.title)
                .font(.system(size: 15))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(height: ToDoView.rowHeight)
        .desktopTextShadow()
    }
}

/// Today, centred on the current hour.
struct RightNowView: View {
    let day: DateRange
    let events: [Event]
    let calendar: Calendar

    var body: some View {
        Box(title: "Right Now") {
            GeometryReader { geometry in
                RightNowTimeline(day: day, events: events, calendar: calendar, height: geometry.size.height)
            }
        }
    }
}

/// The scrolling part of Right Now. It is the only part of the box that depends on the current minute.
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
                .offset(y: fit.offset(ofHour: nowHour))
        }
        .animation(reduceMotion ? nil : .smooth(duration: 0.8), value: start)
        .mask {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.08),
                    .init(color: .black, location: 0.92),
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
