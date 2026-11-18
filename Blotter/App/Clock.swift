import AppKit
import Observation

/// Publishes the current minute and calendar, and updates them when the clock, time zone, locale or day changes,
/// or the Mac wakes from sleep.
@Observable
final class Clock {
    private(set) var now = Date()
    private(set) var calendar = Calendar.autoupdatingCurrent

    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var observers: [any NSObjectProtocol] = []

    init() {
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
        observers.append(
            NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.refresh(rebuildCalendar: false) }
            })
    }

    private func refresh(rebuildCalendar: Bool) {
        if rebuildCalendar {
            calendar = Calendar.autoupdatingCurrent
        }
        now = Date()
        scheduleTimer()
    }

    /// Fires at the start of every minute.
    private func scheduleTimer() {
        timer?.invalidate()
        let current = Date()
        let nextMinute = (current.timeIntervalSinceReferenceDate / 60).rounded(.down) * 60 + 60
        let timer = Timer(
            fire: Date(timeIntervalSinceReferenceDate: nextMinute), interval: 60, repeats: true
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.now = Date() }
        }
        timer.tolerance = 1
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
}
