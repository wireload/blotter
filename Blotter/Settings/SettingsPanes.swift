import AppKit
import BlotterKit
import EventKit
import KeyboardShortcuts
import OSLog
import ServiceManagement
import SwiftUI

struct GeneralSettings: View {
    @AppStorage(DefaultsKey.showsMenuBarItem) private var showsMenuBarItem = true
    @AppStorage(DefaultsKey.autoFades) private var autoFades = false
    @AppStorage(DefaultsKey.autoFadeSeconds) private var autoFadeSeconds = 60
    @AppStorage(DefaultsKey.showsNext7Days) private var showsNext7Days = false
    @AppStorage(DefaultsKey.showsWeekdayDates) private var showsWeekdayDates = true
    @State private var opensAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section {
                Toggle("Open at login", isOn: $opensAtLogin)
                    .onChange(of: opensAtLogin) { _, enabled in
                        setOpensAtLogin(enabled)
                    }
                Toggle(isOn: $showsMenuBarItem) {
                    Text("Show menu bar icon")
                    Text("When hidden, open Blotter again from Finder to get back to Settings.")
                }
            }
            Section {
                Toggle(isOn: $autoFades) {
                    Text("Fade when idle")
                    Text("Dims the calendar after a period without interaction.")
                }
                if autoFades {
                    Stepper(value: $autoFadeSeconds, in: 5...3_600, step: 5) {
                        Text("After \(autoFadeSeconds) seconds")
                    }
                }
            }
            Section {
                Toggle("Show the next 7 days instead of the calendar week", isOn: $showsNext7Days)
                Toggle("Show dates in day titles", isOn: $showsWeekdayDates)
                LabeledContent("Date and time formats") {
                    Button("Language & Region…") {
                        open("x-apple.systempreferences:com.apple.Localization-Settings.extension")
                    }
                }
            }
            Section {
                HStack {
                    Spacer()
                    Button("Quit Blotter") { NSApp.terminate(nil) }
                }
            }
        }
    }

    private func setOpensAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            Logger(subsystem: "net.wireload.blotter.mac", category: "Settings")
                .error("Could not change the login item: \(error.localizedDescription, privacy: .public)")
        }
        opensAtLogin = SMAppService.mainApp.status == .enabled
    }
}

struct ShortcutSettings: View {
    var body: some View {
        Form {
            Section {
                KeyboardShortcuts.Recorder("Bring to front:", name: .toggleFront)
                KeyboardShortcuts.Recorder("New event:", name: .newEvent)
                KeyboardShortcuts.Recorder("New reminder:", name: .newReminder)
            }
            Section {
                KeyboardShortcuts.Recorder("Next week:", name: .nextWeek)
                KeyboardShortcuts.Recorder("Previous week:", name: .previousWeek)
                KeyboardShortcuts.Recorder("Current week:", name: .currentWeek)
            } footer: {
                Text("Shortcuts work from any app.")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct PositionSettings: View {
    @AppStorage(DefaultsKey.screenID) private var screenID = ""
    @AppStorage(DefaultsKey.calendarSize) private var size = CalendarSize.normal.rawValue
    @AppStorage(DefaultsKey.calendarPosition) private var position = CalendarPosition.topLeft.rawValue
    @State private var customFrame = AppDefaults.customFrame
    @State private var screens = NSScreen.screens.map { ScreenChoice($0) }

    var body: some View {
        Form {
            Section {
                Picker("Display", selection: selectedScreen) {
                    ForEach(screens) { screen in
                        Text(screen.name).tag(screen.id)
                    }
                    if !screens.contains(where: { $0.id == screenID }), !screenID.isEmpty {
                        Text("Disconnected display").tag(screenID)
                    }
                }
                Picker("Size", selection: $size) {
                    Text("Narrow").tag(CalendarSize.narrow.rawValue)
                    Text("Normal").tag(CalendarSize.normal.rawValue)
                    Text("Full screen").tag(CalendarSize.full.rawValue)
                    Text("Custom").tag(CalendarSize.custom.rawValue)
                }
                .onChange(of: size) { oldValue, newValue in
                    if newValue == CalendarSize.custom.rawValue, oldValue != newValue {
                        adoptCurrentFrameAsCustom(previousSize: oldValue)
                    }
                }
            }
            if size == CalendarSize.custom.rawValue {
                Section("Custom frame") {
                    percentSlider("Left", value: $customFrame.origin.x, range: 0...(1 - customFrame.width))
                    percentSlider("Bottom", value: $customFrame.origin.y, range: 0...(1 - customFrame.height))
                    percentSlider("Width", value: $customFrame.size.width, range: 0.1...1)
                    percentSlider("Height", value: $customFrame.size.height, range: 0.1...1)
                }
                .onChange(of: customFrame) { _, frame in
                    AppDefaults.customFrame = frame
                }
            } else {
                Section("Position") {
                    AnchorPicker(selection: $position)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) {
            _ in
            screens = NSScreen.screens.map { ScreenChoice($0) }
        }
    }

    private var selectedScreen: Binding<String> {
        Binding(
            get: { screenID.isEmpty ? (NSScreen.screens.first?.blotterID ?? "") : screenID },
            set: { screenID = $0 })
    }

    private func percentSlider(_ title: LocalizedStringKey, value: Binding<CGFloat>, range: ClosedRange<CGFloat>)
        -> some View
    {
        LabeledContent(title) {
            HStack {
                Slider(value: value, in: range.lowerBound...max(range.upperBound, range.lowerBound + 0.01))
                Text(value.wrappedValue, format: .percent.precision(.fractionLength(0)))
                    .monospacedDigit()
                    .frame(width: 44, alignment: .trailing)
            }
        }
    }

    /// Switching to Custom starts from where the calendar currently is.
    private func adoptCurrentFrameAsCustom(previousSize: Int) {
        guard let screen = DesktopWindowController.targetScreen() else { return }
        let frame = WindowGeometry.frame(
            in: screen.visibleFrame,
            size: CalendarSize(rawValue: previousSize) ?? .normal,
            position: CalendarPosition(rawValue: position) ?? .topLeft)
        customFrame = WindowGeometry.customFactors(for: frame, in: screen.visibleFrame)
        AppDefaults.customFrame = customFrame
    }
}

private struct ScreenChoice: Identifiable {
    let id: String
    let name: String

    init(_ screen: NSScreen) {
        id = screen.blotterID ?? ""
        let size = screen.frame.size
        name = "\(screen.localizedName), \(Int(size.width)) × \(Int(size.height))"
    }
}

/// Nine buttons arranged like the screen, one per anchor.
private struct AnchorPicker: View {
    @Binding var selection: Int

    var body: some View {
        Grid(horizontalSpacing: 6, verticalSpacing: 6) {
            ForEach(0..<3) { row in
                GridRow {
                    ForEach(0..<3) { column in
                        let anchor = row * 3 + column
                        Button {
                            selection = anchor
                        } label: {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(anchor == selection ? Color.accentColor : Color.secondary.opacity(0.25))
                                .frame(width: 56, height: 34)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Self.name(of: anchor))
                        .accessibilityAddTraits(anchor == selection ? .isSelected : [])
                    }
                }
            }
        }
        .padding(8)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }

    private static func name(of anchor: Int) -> String {
        let rows = [String(localized: "Top"), String(localized: "Middle"), String(localized: "Bottom")]
        let columns = [String(localized: "left"), String(localized: "centre"), String(localized: "right")]
        return "\(rows[anchor / 3]) \(columns[anchor % 3])"
    }
}

struct LayoutSettings: View {
    @AppStorage(DefaultsKey.calendarLayout) private var layout = CalendarLayout.normal.rawValue
    @AppStorage(DefaultsKey.infoWidth) private var infoWidth = 250.0
    @AppStorage(DefaultsKey.dateHeight) private var dateHeight = 250.0
    @AppStorage(DefaultsKey.toDoHeight) private var toDoHeight = 200.0
    @AppStorage(DefaultsKey.allDayHeight) private var allDayHeight = 110.0

    var body: some View {
        Form {
            Section {
                Picker("Beside the week", selection: $layout) {
                    Text("To Do and Right Now").tag(CalendarLayout.normal.rawValue)
                    Text("To Do only").tag(CalendarLayout.toDo.rawValue)
                    Text("Right Now only").tag(CalendarLayout.rightNow.rawValue)
                    Text("Custom").tag(CalendarLayout.custom.rawValue)
                }
            }
            Section("Sizes") {
                pointSlider("Info column width", value: $infoWidth, range: 230...700)
                    .disabled(layout != CalendarLayout.custom.rawValue)
                pointSlider("Date height", value: $dateHeight, range: 0...500)
                pointSlider("To Do height", value: $toDoHeight, range: 100...900)
                    .disabled(layout != CalendarLayout.custom.rawValue)
                pointSlider("All-day events height", value: $allDayHeight, range: 0...300)
            }
        }
    }

    private func pointSlider(_ title: LocalizedStringKey, value: Binding<Double>, range: ClosedRange<Double>)
        -> some View
    {
        LabeledContent(title) {
            HStack {
                Slider(value: value, in: range, step: 5)
                Text("\(Int(value.wrappedValue)) pt")
                    .monospacedDigit()
                    .frame(width: 52, alignment: .trailing)
            }
        }
    }
}

struct CalendarSettings: View {
    @Environment(CalendarStore.self) private var store
    @AppStorage(DefaultsKey.showsAllCalendars) private var showsAllCalendars = true

    var body: some View {
        Form {
            if store.eventAccess == .denied || store.reminderAccess == .denied {
                Section {
                    Text("Blotter needs full access to your calendars and reminders to show them.")
                    Button("Open Privacy & Security Settings…") {
                        open("x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")
                    }
                }
            }
            Section {
                Picker("Show", selection: $showsAllCalendars) {
                    Text("All calendars").tag(true)
                    Text("Selected calendars").tag(false)
                }
                .pickerStyle(.radioGroup)
            }
            if !showsAllCalendars {
                calendarSection("Events", calendars: store.eventCalendars, type: .event)
                calendarSection("Reminders", calendars: store.reminderCalendars, type: .reminder)
            }
        }
    }

    private func calendarSection(_ title: LocalizedStringKey, calendars: [CalendarInfo], type: EKEntityType)
        -> some View
    {
        Section(title) {
            ForEach(calendars) { calendar in
                Toggle(
                    isOn: Binding(
                        get: { store.isShown(calendar, for: type) },
                        set: { store.setShown($0, calendar: calendar, for: type) })
                ) {
                    HStack(spacing: 6) {
                        Circle().fill(Color(calendar.color)).frame(width: 10, height: 10)
                        Text(calendar.title)
                        if !calendar.sourceTitle.isEmpty {
                            Text(calendar.sourceTitle).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

struct AboutSettings: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
            Text("Blotter")
                .font(.title.bold())
            Text("Version \(Bundle.main.shortVersion) (\(Bundle.main.buildNumber))")
                .foregroundStyle(.secondary)
            Text("Your calendar on the desktop.")
            Link("Source code on GitHub", destination: URL(string: "https://github.com/wireload/blotter")!)
            Text(Bundle.main.copyright)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }
}

extension Bundle {
    var shortVersion: String { object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "" }
    var buildNumber: String { object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "" }
    var copyright: String { object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String ?? "" }
}

@MainActor
private func open(_ url: String) {
    if let url = URL(string: url) {
        NSWorkspace.shared.open(url)
    }
}
