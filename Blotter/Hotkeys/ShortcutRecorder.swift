import AppKit
import BlotterKit
import SwiftUI

/// A field that records a global shortcut for one action: click it, then press the shortcut.
///
/// Escape cancels, and Delete clears the shortcut.
struct ShortcutRecorder: View {
    let action: HotkeyAction

    @State private var store = HotkeyStore.shared
    @State private var isRecording = false
    @State private var monitor: Any?
    @State private var problem: HotkeyStore.AssignmentError?

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 4) {
                Button(action: toggleRecording) {
                    Text(label)
                        .monospacedDigit()
                        .foregroundStyle(isRecording || store.combo(for: action) == nil ? .secondary : .primary)
                        .frame(minWidth: 110)
                }
                .accessibilityLabel(accessibilityLabel)
                .accessibilityHint(Text("Click, then press the shortcut."))

                if store.combo(for: action) != nil, !isRecording {
                    Button {
                        store.set(nil, for: action)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Clear shortcut"))
                }
            }
            if let problem {
                Text(message(for: problem))
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .onDisappear(perform: stopRecording)
    }

    private var label: String {
        if isRecording { return String(localized: "Press shortcut…") }
        guard let combo = store.combo(for: action) else { return String(localized: "Record Shortcut") }
        return KeyDisplay.string(for: combo)
    }

    private var accessibilityLabel: String {
        guard let combo = store.combo(for: action) else { return String(localized: "Record Shortcut") }
        return KeyDisplay.string(for: combo)
    }

    private func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    private func startRecording() {
        problem = nil
        isRecording = true
        // Existing shortcuts would fire instead of being recorded.
        HotkeyCenter.shared.pause()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            MainActor.assumeIsolated { record(event) } ? nil : event
        }
    }

    private func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        HotkeyCenter.shared.resume(store: store)
    }

    /// Returns whether the event was consumed.
    private func record(_ event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let plain = modifiers.isDisjoint(with: [.command, .option, .control, .shift])
        switch event.keyCode {
        case 0x35 where plain:  // Escape
            stopRecording()
            return true
        case 0x33 where plain, 0x75 where plain:  // Delete, Forward Delete
            store.set(nil, for: action)
            stopRecording()
            return true
        default:
            break
        }

        let combo = KeyCombo(keyCode: event.keyCode, modifiers: KeyCombo.Modifiers(rawValue: modifiers.rawValue))
        if let problem = store.validate(combo, for: action) {
            self.problem = problem
            NSSound.beep()
            return true
        }
        problem = nil
        stopRecording()
        store.set(combo, for: action)
        return true
    }

    private func message(for problem: HotkeyStore.AssignmentError) -> String {
        switch problem {
        case .needsModifier:
            String(localized: "Use at least one of ⌘, ⌥ or ⌃.")
        case .usedBy(let other):
            String(localized: "Already used for “\(Self.name(of: other))”.")
        case .unavailable:
            String(localized: "macOS already uses this shortcut.")
        }
    }

    static func name(of action: HotkeyAction) -> String {
        switch action {
        case .toggleFront: String(localized: "Bring to Front")
        case .newEvent: String(localized: "New Event")
        case .newReminder: String(localized: "New Reminder")
        case .nextWeek: String(localized: "Next Week")
        case .previousWeek: String(localized: "Previous Week")
        case .currentWeek: String(localized: "Current Week")
        }
    }
}
