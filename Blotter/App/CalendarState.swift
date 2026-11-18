import BlotterKit
import Foundation
import Observation

/// What the calendar window shows and how it is presented.
@Observable
final class CalendarState {
    enum Presentation {
        /// Behind icons and every other window, on all Spaces.
        case desktop
        /// Floating above other windows after "Bring to Front".
        case front
    }

    /// How long after navigating away the calendar returns to the current week.
    static let returnToCurrentWeekDelay: Duration = .seconds(45)

    /// Whole weeks away from the current week.
    var weekOffset = 0 {
        didSet {
            guard weekOffset != oldValue else { return }
            lastNavigationWasForward = weekOffset > oldValue
            noteActivity()
            scheduleReturnToCurrentWeek()
        }
    }
    private(set) var lastNavigationWasForward = true
    private(set) var presentation = Presentation.desktop
    /// Dimmed after a period without interaction, when auto-fade is on.
    private(set) var isFaded = false

    /// Called whenever `presentation` or `isFaded` changes.
    @ObservationIgnored var onPresentationChange: (() -> Void)?

    @ObservationIgnored private var returnTask: Task<Void, Never>?
    @ObservationIgnored private var fadeTask: Task<Void, Never>?

    func bringToFront() {
        presentation = .front
        isFaded = false
        fadeTask?.cancel()
        onPresentationChange?()
    }

    func sendToBack() {
        guard presentation != .desktop else { return }
        presentation = .desktop
        onPresentationChange?()
        scheduleFade()
    }

    /// Fades the calendar back in and restarts the auto-fade countdown.
    func noteActivity() {
        if isFaded {
            isFaded = false
            onPresentationChange?()
        }
        scheduleFade()
    }

    private func scheduleFade() {
        fadeTask?.cancel()
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: DefaultsKey.autoFades), weekOffset == 0, presentation == .desktop else { return }
        let seconds = max(defaults.integer(forKey: DefaultsKey.autoFadeSeconds), 5)
        fadeTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled, let self else { return }
            self.isFaded = true
            self.onPresentationChange?()
        }
    }

    private func scheduleReturnToCurrentWeek() {
        returnTask?.cancel()
        guard weekOffset != 0 else { return }
        returnTask = Task { [weak self] in
            try? await Task.sleep(for: Self.returnToCurrentWeekDelay)
            guard !Task.isCancelled else { return }
            self?.weekOffset = 0
        }
    }
}
