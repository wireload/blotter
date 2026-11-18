import BlotterKit
import SwiftUI

/// Today's date, large.
struct DateView: View {
    let date: Date

    var body: some View {
        VStack(spacing: 0) {
            Text(date, format: .dateTime.day())
                .font(.system(size: 200, weight: .ultraLight))
                .minimumScaleFactor(0.3)
                .lineLimit(1)
            Text(date, format: .dateTime.month(.wide).year())
                .font(.system(size: 26, weight: .light))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(date, format: .dateTime.weekday(.wide))
                .font(.system(size: 26, weight: .light))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .desktopTextShadow()
        .accessibilityElement(children: .combine)
    }
}

/// Incomplete reminders.
struct ToDoView: View {
    let reminders: [Reminder]
    let access: CalendarStore.Access

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
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color(reminder.color))
                                    .frame(width: 8, height: 8)
                                Text(reminder.title)
                                    .font(.system(size: 15))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .frame(height: Self.rowHeight)
                            .desktopTextShadow()
                        }
                    }
                    .animation(.default, value: reminders.map(\.id))
                }
            }
        }
    }
}

/// Today, centred on the current hour.
struct RightNowView: View {
    let day: DateRange
    let events: [Event]
    let now: Date
    let calendar: Calendar

    var body: some View {
        Box(title: "Right Now") {
            GeometryReader { geometry in
                let height = geometry.size.height
                let hourHeight = max(40, (height / 24).rounded())
                let visibleHours = Double(height / hourHeight)
                let nowHour = Schedule.hour(of: now, on: day, calendar: calendar)
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
    }
}

/// Shown in place of content when calendar or reminder access was refused.
struct AccessHint: View {
    let text: LocalizedStringKey

    var body: some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.white.opacity(0.75))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .multilineTextAlignment(.center)
    }
}
