import BlotterKit
import Foundation
import Observation

/// The user's global shortcuts, persisted in user defaults. None are assigned by default.
@Observable
final class HotkeyStore {
    static let shared = HotkeyStore()

    enum AssignmentError: Error, Equatable {
        /// Needs ⌘, ⌥ or ⌃ (or a function key).
        case needsModifier
        /// Already used by another Blotter action.
        case usedBy(HotkeyAction)
        /// macOS or another app has claimed the shortcut.
        case unavailable
    }

    private(set) var combos: [HotkeyAction: KeyCombo] = [:]

    /// Called after any change, to register the new set of shortcuts.
    @ObservationIgnored var onChange: (() -> Void)?

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        for action in HotkeyAction.allCases {
            if let data = defaults.data(forKey: action.defaultsKey),
                let combo = try? JSONDecoder().decode(KeyCombo.self, from: data)
            {
                combos[action] = combo
            }
        }
    }

    func combo(for action: HotkeyAction) -> KeyCombo? { combos[action] }

    /// Checks a shortcut before it is assigned to `action`.
    func validate(_ combo: KeyCombo, for action: HotkeyAction) -> AssignmentError? {
        if !combo.isValid { return .needsModifier }
        if let other = KeyCombo.conflict(for: combo, assigningTo: action, in: combos) { return .usedBy(other) }
        if HotkeyCenter.isReservedBySystem(combo) { return .unavailable }
        return nil
    }

    /// Assigns (or, with `nil`, clears) the shortcut for `action`. Validation is the caller's job.
    func set(_ combo: KeyCombo?, for action: HotkeyAction) {
        combos[action] = combo
        if let combo, let data = try? JSONEncoder().encode(combo) {
            defaults.set(data, forKey: action.defaultsKey)
        } else {
            defaults.removeObject(forKey: action.defaultsKey)
        }
        onChange?()
    }
}
