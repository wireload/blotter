import AppKit
import BlotterKit
import EventKit
import OSLog
import Observation

/// A calendar or reminder list the user can show or hide.
struct CalendarInfo: Identifiable, Hashable {
    let id: String
    let title: String
    let sourceTitle: String
    let color: RGBAColor
    let allowsModifications: Bool
}

/// Reads and writes events and reminders through EventKit, and republishes them as BlotterKit values.
@Observable
final class CalendarStore {
    enum Access {
        case notDetermined
        case granted
        case denied
    }

    private(set) var eventAccess: Access
    private(set) var reminderAccess: Access
    private(set) var eventCalendars: [CalendarInfo] = []
    private(set) var reminderCalendars: [CalendarInfo] = []
    private(set) var events: [Event] = []
    private(set) var reminders: [Reminder] = []

    /// The time spans events are loaded for (the visible week, and today for Right Now).
    var visibleRanges: [DateRange] = [] {
        didSet {
            if visibleRanges != oldValue { reloadEvents() }
        }
    }

    @ObservationIgnored private let store = EKEventStore()
    @ObservationIgnored private var observers: [any NSObjectProtocol] = []
    @ObservationIgnored private var hiddenCalendarsSnapshot: [String] = []
    @ObservationIgnored private var reminderFetch: Any?
    /// Incremented on every reminders fetch, so a late result from an older fetch is discarded.
    @ObservationIgnored private var reminderGeneration = 0
    @ObservationIgnored private var accessTimer: Timer?
    @ObservationIgnored private var pendingReload: DispatchWorkItem?
    @ObservationIgnored private let log = Logger(subsystem: "net.wireload.blotter.mac", category: "CalendarStore")

    @ObservationIgnored private let isDemo = DemoData.isEnabled

    init() {
        eventAccess = isDemo ? .granted : Self.access(for: .event)
        reminderAccess = isDemo ? .granted : Self.access(for: .reminder)
        hiddenCalendarsSnapshot = Self.hiddenCalendarsSnapshot()

        let center = NotificationCenter.default
        observers.append(
            center.addObserver(forName: .EKEventStoreChanged, object: store, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.scheduleReload() }
            })
        observers.append(
            center.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) {
                [weak self] _ in
                MainActor.assumeIsolated { self?.calendarSelectionMayHaveChanged() }
            })
        reload()
        updateAccessTimer()
    }

    // MARK: Access

    func requestAccess() {
        guard !isDemo else { return }
        if eventAccess == .notDetermined {
            store.requestFullAccessToEvents { @Sendable [weak self] _, _ in
                Task { @MainActor in self?.accessChanged() }
            }
        }
        if reminderAccess == .notDetermined {
            store.requestFullAccessToReminders { @Sendable [weak self] _, _ in
                Task { @MainActor in self?.accessChanged() }
            }
        }
    }

    private func accessChanged() {
        refreshAccess()
    }

    /// Re-reads the authorization status, which the user can change in System Settings at any time.
    func refreshAccess() {
        guard !isDemo else { return }
        let events = Self.access(for: .event)
        let reminders = Self.access(for: .reminder)
        guard events != eventAccess || reminders != reminderAccess else { return }
        let gained =
            (events == .granted && eventAccess != .granted) || (reminders == .granted && reminderAccess != .granted)
        eventAccess = events
        reminderAccess = reminders
        if gained {
            // A store created before access was granted can keep returning nothing until it is reset.
            store.reset()
        }
        reload()
        updateAccessTimer()
    }

    /// While some access is missing, check now and then whether it was granted in System Settings.
    private func updateAccessTimer() {
        let complete = isDemo || (eventAccess == .granted && reminderAccess == .granted)
        if complete {
            accessTimer?.invalidate()
            accessTimer = nil
        } else if accessTimer == nil {
            let timer = Timer(timeInterval: 10, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.refreshAccess() }
            }
            timer.tolerance = 5
            RunLoop.main.add(timer, forMode: .common)
            accessTimer = timer
        }
    }

    private static func access(for type: EKEntityType) -> Access {
        switch EKEventStore.authorizationStatus(for: type) {
        case .fullAccess: .granted
        case .notDetermined: .notDetermined
        default: .denied
        }
    }

    // MARK: Loading

    private func reload() {
        if isDemo {
            eventCalendars = DemoData.eventCalendars
            reminderCalendars = DemoData.reminderCalendars
            reloadEvents()
            reminders = DemoData.reminders(around: Date(), calendar: .current)
            return
        }
        if eventAccess == .granted {
            eventCalendars = store.calendars(for: .event).map(Self.info).sorted(by: Self.calendarOrder)
        } else {
            eventCalendars = []
        }
        if reminderAccess == .granted {
            reminderCalendars = store.calendars(for: .reminder).map(Self.info).sorted(by: Self.calendarOrder)
        } else {
            reminderCalendars = []
        }
        reloadEvents()
        reloadReminders()
    }

    /// Syncing posts bursts of change notifications; reload once they settle.
    private func scheduleReload() {
        pendingReload?.cancel()
        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated { self?.reload() }
        }
        pendingReload = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    private func calendarSelectionMayHaveChanged() {
        let snapshot = Self.hiddenCalendarsSnapshot()
        guard snapshot != hiddenCalendarsSnapshot else { return }
        hiddenCalendarsSnapshot = snapshot
        reloadEvents()
        reloadReminders()
    }

    private func reloadEvents() {
        let ranges = visibleRanges
        guard eventAccess == .granted, !ranges.isEmpty else {
            events = []
            return
        }
        if isDemo {
            events = DemoData.events(around: Date(), calendar: .current).filter { event in
                ranges.contains { $0.intersects(event.range) || $0.position(of: event.start) == .within }
            }
            return
        }
        let calendars = visibleCalendars(for: .event)
        guard !calendars.isEmpty else {
            events = []
            return
        }
        // Each range is fetched on its own; an event in more than one (today, in the visible week) is kept once.
        var seen = Set<String>()
        var loaded: [Event] = []
        for range in ranges {
            let predicate = store.predicateForEvents(withStart: range.start, end: range.end, calendars: calendars)
            for event in store.events(matching: predicate).map(Self.event) where seen.insert(event.id).inserted {
                loaded.append(event)
            }
        }
        events = loaded
    }

    private func reloadReminders() {
        guard !isDemo else { return }
        reminderGeneration += 1
        let generation = reminderGeneration
        if let reminderFetch {
            store.cancelFetchRequest(reminderFetch)
            self.reminderFetch = nil
        }
        guard reminderAccess == .granted else {
            reminders = []
            return
        }
        let calendars = visibleCalendars(for: .reminder)
        guard !calendars.isEmpty else {
            reminders = []
            return
        }
        let predicate = store.predicateForIncompleteReminders(
            withDueDateStarting: nil, ending: nil, calendars: calendars)
        reminderFetch = store.fetchReminders(matching: predicate) { @Sendable [weak self] fetched in
            let reminders = (fetched ?? []).map(Self.reminder).sorted(by: Reminder.areInDisplayOrder)
            Task { @MainActor in
                guard let self, self.reminderGeneration == generation else { return }
                self.reminders = reminders
            }
        }
    }

    private func visibleCalendars(for type: EKEntityType) -> [EKCalendar] {
        let all = store.calendars(for: type)
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: DefaultsKey.showsAllCalendars) else { return all }
        let hidden = Set(Self.hiddenCalendars(for: type))
        return all.filter { !hidden.contains($0.calendarIdentifier) }
    }

    // MARK: Calendar selection

    func isShown(_ calendar: CalendarInfo, for type: EKEntityType) -> Bool {
        !Self.hiddenCalendars(for: type).contains(calendar.id)
    }

    func setShown(_ shown: Bool, calendar: CalendarInfo, for type: EKEntityType) {
        var hidden = Set(Self.hiddenCalendars(for: type))
        if shown {
            hidden.remove(calendar.id)
        } else {
            hidden.insert(calendar.id)
        }
        UserDefaults.standard.set(hidden.sorted(), forKey: Self.hiddenCalendarsKey(for: type))
    }

    private static func hiddenCalendarsKey(for type: EKEntityType) -> String {
        type == .event ? DefaultsKey.hiddenEventCalendars : DefaultsKey.hiddenReminderCalendars
    }

    private static func hiddenCalendars(for type: EKEntityType) -> [String] {
        UserDefaults.standard.stringArray(forKey: hiddenCalendarsKey(for: type)) ?? []
    }

    private static func hiddenCalendarsSnapshot() -> [String] {
        let defaults = UserDefaults.standard
        return [defaults.bool(forKey: DefaultsKey.showsAllCalendars) ? "all" : "selected"]
            + hiddenCalendars(for: .event) + ["|"] + hiddenCalendars(for: .reminder)
    }

    // MARK: Creating

    func createEvent(
        title: String, location: String, start: Date, end: Date, isAllDay: Bool, calendarID: String
    ) throws {
        guard !isDemo else { return }
        let event = EKEvent(eventStore: store)
        event.title = title
        event.location = location.isEmpty ? nil : location
        event.startDate = start
        event.endDate = end
        event.isAllDay = isAllDay
        event.calendar = store.calendar(withIdentifier: calendarID) ?? store.defaultCalendarForNewEvents
        try store.save(event, span: .thisEvent, commit: true)
    }

    func createReminder(title: String, dueDate: Date?, priority: Int, calendarID: String) throws {
        guard !isDemo else { return }
        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.priority = priority
        if let dueDate {
            // A date-only, floating due date: no time of day and no time zone, as in Reminders.
            reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
        }
        reminder.calendar = store.calendar(withIdentifier: calendarID) ?? store.defaultCalendarForNewReminders()
        try store.save(reminder, commit: true)
    }

    var defaultEventCalendarID: String? { store.defaultCalendarForNewEvents?.calendarIdentifier }

    var defaultReminderCalendarID: String? { store.defaultCalendarForNewReminders()?.calendarIdentifier }

    // MARK: Conversion

    nonisolated private static func info(_ calendar: EKCalendar) -> CalendarInfo {
        CalendarInfo(
            id: calendar.calendarIdentifier,
            title: calendar.title,
            sourceTitle: calendar.source?.title ?? "",
            color: rgba(calendar.color),
            allowsModifications: calendar.allowsContentModifications
        )
    }

    nonisolated private static func calendarOrder(_ a: CalendarInfo, _ b: CalendarInfo) -> Bool {
        if a.sourceTitle != b.sourceTitle {
            return a.sourceTitle.localizedStandardCompare(b.sourceTitle) == .orderedAscending
        }
        return a.title.localizedStandardCompare(b.title) == .orderedAscending
    }

    nonisolated private static func event(_ event: EKEvent) -> Event {
        let start: Date = event.startDate ?? Date()
        let location = event.location?.trimmingCharacters(in: .whitespacesAndNewlines)
        return Event(
            // Occurrences of a recurring event share an identifier; the start date tells them apart.
            id: "\(event.calendarItemIdentifier)@\(start.timeIntervalSinceReferenceDate)",
            title: (event.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            location: location?.isEmpty == false ? location : nil,
            start: start,
            end: event.endDate ?? start,
            isAllDay: event.isAllDay,
            calendarID: event.calendar?.calendarIdentifier ?? "",
            color: rgba(event.calendar?.color)
        )
    }

    nonisolated private static func reminder(_ reminder: EKReminder) -> Reminder {
        Reminder(
            id: reminder.calendarItemIdentifier,
            title: (reminder.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            dueDate: reminder.dueDateComponents.flatMap { Calendar.current.date(from: $0) },
            priority: reminder.priority,
            calendarID: reminder.calendar?.calendarIdentifier ?? "",
            calendarTitle: reminder.calendar?.title ?? "",
            color: rgba(reminder.calendar?.color)
        )
    }

    nonisolated private static func rgba(_ color: NSColor?) -> RGBAColor {
        guard let color = color?.usingColorSpace(.sRGB) else { return .fallback }
        return RGBAColor(
            red: Double(color.redComponent), green: Double(color.greenComponent), blue: Double(color.blueComponent),
            alpha: Double(color.alphaComponent))
    }
}
