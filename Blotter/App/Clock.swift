import AppKit
import Observation

/// Publishes the current minute, today's date and the calendar, and updates them when the clock, time zone, locale
/// or day changes, or the Mac wakes.
///
/// `now` changes every minute and `today` once a day, so views that only need the date should read `today`: SwiftUI
/// then leaves them alone on minute ticks.
@Observable
final class Clock {
    private(set) var now = Date()
    /// Start of the current day.
    private(set) var today: Date
    private(set) var calendar = Calendar.autoupdatingCurrent

    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var observers: [any NSObjectProtocol] = []

    init() {
        today = Calendar.autoupdatingCurrent.startOfDay(for: Date())
        scheduleTimer()

        let center = NotificationCenter.default
        for name in [
            Notification.Name.NSSystemClockDidChange, .NSSystemTimeZoneDidChange, .NSCalendarDayChanged,
            NSLocale.currentLocaleDidChangeNotification,
        ] {
            observers.append(
                center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated { self?.refresh(rebuildCalendar: true) }
                })
        }

        // Nothing is visible while the displays sleep, so stop ticking until they wake.
        let workspace = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.screensDidSleepNotification, NSWorkspace.sessionDidResignActiveNotification] {
            observers.append(
                workspace.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated { self?.pause() }
                })
        }
        for name in [
            NSWorkspace.didWakeNotification, NSWorkspace.screensDidWakeNotification,
            NSWorkspace.sessionDidBecomeActiveNotification,
        ] {
            observers.append(
                workspace.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated { self?.refresh(rebuildCalendar: false) }
                })
        }
    }

    private func refresh(rebuildCalendar: Bool) {
        if rebuildCalendar {
            calendar = Calendar.autoupdatingCurrent
        }
        tick()
        scheduleTimer()
    }

    private func tick() {
        let date = Date()
        now = date
        let day = calendar.startOfDay(for: date)
        if day != today {
            today = day
        }
    }

    private func pause() {
        timer?.invalidate()
        timer = nil
    }

    /// Fires at the start of every minute.
    private func scheduleTimer() {
        timer?.invalidate()
        let current = Date()
        let nextMinute = (current.timeIntervalSinceReferenceDate / 60).rounded(.down) * 60 + 60
        let timer = Timer(
            fire: Date(timeIntervalSinceReferenceDate: nextMinute), interval: 60, repeats: true
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        // A few seconds of slack lets macOS coalesce wake-ups; the minute display does not need more precision.
        timer.tolerance = 5
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
}
