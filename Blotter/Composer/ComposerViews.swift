import BlotterKit
import SwiftUI

struct NewEventView: View {
    let close: () -> Void

    @Environment(CalendarStore.self) private var store
    @AppStorage(DefaultsKey.lastEventCalendar) private var calendarID = ""

    @State private var title = String(localized: "New Event")
    @State private var location = ""
    @State private var isAllDay = false
    @State private var start: Date
    @State private var end: Date
    @State private var error: String?
    @FocusState private var titleFocused: Bool

    init(close: @escaping () -> Void) {
        self.close = close
        let start = Date.nextFullHour()
        _start = State(initialValue: start)
        _end = State(initialValue: start.addingTimeInterval(3_600))
    }

    var body: some View {
        Form {
            TextField("Title", text: $title)
                .focused($titleFocused)
            TextField("Location", text: $location)
            Toggle("All day", isOn: $isAllDay)
            DatePicker("Starts", selection: $start, displayedComponents: components)
                .onChange(of: start) { oldValue, newValue in
                    // Moving the start moves the whole event, keeping its duration, as in Calendar.
                    end = end.addingTimeInterval(newValue.timeIntervalSince(oldValue))
                }
            DatePicker("Ends", selection: $end, in: start..., displayedComponents: components)
            CalendarPicker(
                calendars: store.eventCalendars, selection: $calendarID, fallback: store.defaultEventCalendarID)
            if let error {
                Text(error).foregroundStyle(.red).font(.callout)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .fixedSize(horizontal: false, vertical: true)
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                Button("Cancel", action: close).keyboardShortcut(.cancelAction)
                Button("Add Event", action: save)
                    .keyboardShortcut(.defaultAction)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding([.horizontal, .bottom], 20)
        }
        .onAppear { titleFocused = true }
    }

    private var components: DatePickerComponents {
        isAllDay ? [.date] : [.date, .hourAndMinute]
    }

    private func save() {
        var start = start
        var end = end
        if isAllDay {
            // The pickers hide the time, but it is still there: drop it so the event covers exactly the chosen days.
            let calendar = Calendar.current
            start = calendar.startOfDay(for: start)
            end = max(calendar.startOfDay(for: end), start)
        }
        do {
            try store.createEvent(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                location: location.trimmingCharacters(in: .whitespacesAndNewlines),
                start: start, end: end, isAllDay: isAllDay, calendarID: calendarID)
            close()
        } catch {
            NSSound.beep()
            self.error = error.localizedDescription
        }
    }
}

struct NewReminderView: View {
    let close: () -> Void

    @Environment(CalendarStore.self) private var store
    @AppStorage(DefaultsKey.lastReminderCalendar) private var calendarID = ""

    @State private var title = String(localized: "New Reminder")
    @State private var hasDueDate = false
    @State private var dueDate = Date.nextFullHour()
    @State private var priority = 0
    @State private var error: String?
    @FocusState private var titleFocused: Bool

    var body: some View {
        Form {
            TextField("Title", text: $title)
                .focused($titleFocused)
            Toggle("Remind me on a day", isOn: $hasDueDate)
            if hasDueDate {
                DatePicker("Due", selection: $dueDate, displayedComponents: [.date])
            }
            Picker("Priority", selection: $priority) {
                Text("None").tag(0)
                Text("High").tag(1)
                Text("Medium").tag(5)
                Text("Low").tag(9)
            }
            CalendarPicker(
                calendars: store.reminderCalendars, selection: $calendarID, fallback: store.defaultReminderCalendarID)
            if let error {
                Text(error).foregroundStyle(.red).font(.callout)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .fixedSize(horizontal: false, vertical: true)
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                Button("Cancel", action: close).keyboardShortcut(.cancelAction)
                Button("Add Reminder", action: save)
                    .keyboardShortcut(.defaultAction)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding([.horizontal, .bottom], 20)
        }
        .onAppear { titleFocused = true }
    }

    private func save() {
        do {
            try store.createReminder(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                dueDate: hasDueDate ? dueDate : nil, priority: priority, calendarID: calendarID)
            close()
        } catch {
            NSSound.beep()
            self.error = error.localizedDescription
        }
    }
}

/// Picks one of the calendars that can be written to, remembering the last choice.
private struct CalendarPicker: View {
    let calendars: [CalendarInfo]
    @Binding var selection: String
    let fallback: String?

    private var writable: [CalendarInfo] { calendars.filter(\.allowsModifications) }

    var body: some View {
        Picker("Calendar", selection: $selection) {
            ForEach(writable) { calendar in
                Label {
                    Text(calendar.title)
                } icon: {
                    Image(systemName: "circle.fill").foregroundStyle(Color(calendar.color))
                }
                .tag(calendar.id)
            }
        }
        .onAppear {
            if !writable.contains(where: { $0.id == selection }) {
                selection = fallback.flatMap { id in writable.first { $0.id == id }?.id } ?? writable.first?.id ?? ""
            }
        }
    }
}

extension Date {
    /// The start of the next hour.
    static func nextFullHour(after date: Date = Date(), calendar: Calendar = .current) -> Date {
        let hour = calendar.dateInterval(of: .hour, for: date)?.start ?? date
        return calendar.date(byAdding: .hour, value: 1, to: hour) ?? date
    }
}
