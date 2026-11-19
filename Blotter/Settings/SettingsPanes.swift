import AppKit
import BlotterKit
import EventKit
import OSLog
import ServiceManagement
import SwiftUI

struct GeneralSettings: View {
    @AppStorage(DefaultsKey.showsMenuBarItem) private var showsMenuBarItem = true
    @AppStorage(DefaultsKey.autoFades) private var autoFades = false
    @AppStorage(DefaultsKey.autoFadeSeconds) private var autoFadeSeconds = 60
    @AppStorage(DefaultsKey.showsNext7Days) private var showsNext7Days = false
    @AppStorage(DefaultsKey.showsWeekdayDates) private var showsWeekdayDates = true
    @AppStorage(AppDefaults.appearance) private var appearance = AppAppearance.system.rawValue
    @State private var loginItemStatus = SMAppService.mainApp.status

    var body: some View {
        Form {
            Section {
                Toggle("Open at login", isOn: opensAtLogin)
                if loginItemStatus == .requiresApproval {
                    LabeledContent {
                        Button("Open Login Items…") { SMAppService.openSystemSettingsLoginItems() }
                    } label: {
                        Text("Approve Blotter in System Settings › General › Login Items.")
                            .foregroundStyle(.secondary)
                    }
                }
                Toggle(isOn: $showsMenuBarItem) {
                    Text("Show menu bar icon")
                    Text("When hidden, open Blotter again from Finder to get back to Settings.")
                }
            }
            Section {
                Picker("Appearance", selection: $appearance) {
                    Text("System").tag(AppAppearance.system.rawValue)
                    Text("Light").tag(AppAppearance.light.rawValue)
                    Text("Dark").tag(AppAppearance.dark.rawValue)
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
        .onAppear { loginItemStatus = SMAppService.mainApp.status }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            loginItemStatus = SMAppService.mainApp.status
        }
    }

    /// On while registered, including while waiting for the user's approval in System Settings.
    private var opensAtLogin: Binding<Bool> {
        Binding(
            get: { loginItemStatus == .enabled || loginItemStatus == .requiresApproval },
            set: { setOpensAtLogin($0) })
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
        loginItemStatus = SMAppService.mainApp.status
        if loginItemStatus == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
    }
}

struct ShortcutSettings: View {
    var body: some View {
        Form {
            Section {
                LabeledContent("Bring to front:") { ShortcutRecorder(action: .toggleFront) }
                LabeledContent("New event:") { ShortcutRecorder(action: .newEvent) }
                LabeledContent("New reminder:") { ShortcutRecorder(action: .newReminder) }
            }
            Section {
                LabeledContent("Next week:") { ShortcutRecorder(action: .nextWeek) }
                LabeledContent("Previous week:") { ShortcutRecorder(action: .previousWeek) }
                LabeledContent("Current week:") { ShortcutRecorder(action: .currentWeek) }
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
    @AppStorage(DefaultsKey.calendarPosition) private var position = CalendarPosition.defaultPosition.rawValue
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
            position: CalendarPosition(rawValue: position) ?? .defaultPosition)
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
        [
            String(localized: "Top left"), String(localized: "Top center"), String(localized: "Top right"),
            String(localized: "Middle left"), String(localized: "Center"), String(localized: "Middle right"),
            String(localized: "Bottom left"), String(localized: "Bottom center"), String(localized: "Bottom right"),
        ][anchor]
    }
}

struct LayoutSettings: View {
    @AppStorage(DefaultsKey.calendarLayout) private var layout = CalendarLayout.normal.rawValue
    @AppStorage(DefaultsKey.infoWidth) private var infoWidth = 250.0
    @AppStorage(DefaultsKey.dateHeight) private var dateHeight = 250.0
    @AppStorage(DefaultsKey.toDoHeight) private var toDoHeight = 200.0
    @AppStorage(DefaultsKey.allDayHeight) private var allDayHeight = 110.0
    @AppStorage(DefaultsKey.calendarSize) private var size = CalendarSize.normal.rawValue

    private enum Sidebar: Hashable {
        case both, toDo, rightNow
    }

    private static let defaultDateHeight = 250.0
    private static let defaultAllDayHeight = 110.0

    var body: some View {
        Form {
            Section {
                LayoutPreview(panes: panes, size: calendarSize)
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
            }
            Section {
                Picker("Sidebar", selection: sidebar) {
                    Text("To Do and Right Now").tag(Sidebar.both)
                    Text("To Do only").tag(Sidebar.toDo)
                    Text("Right Now only").tag(Sidebar.rightNow)
                }
                Toggle("Show today’s date", isOn: shows($dateHeight, restoring: Self.defaultDateHeight))
                Toggle("Show all-day events", isOn: shows($allDayHeight, restoring: Self.defaultAllDayHeight))
            }
            Section {
                sizeSlider("Sidebar width", value: $infoWidth, range: 230...500, from: "Narrow", to: "Wide")
                if dateHeight > 0 {
                    sizeSlider("Date", value: $dateHeight, range: 180...400, from: "Short", to: "Tall")
                }
                if sidebar.wrappedValue == .both {
                    sizeSlider("To Do", value: customLayout($toDoHeight), range: 100...600, from: "Less", to: "More")
                }
                if allDayHeight > 0 {
                    sizeSlider("All-day events", value: $allDayHeight, range: 50...250, from: "Less", to: "More")
                }
            } header: {
                Text("Sizes")
            } footer: {
                HStack(alignment: .firstTextBaseline) {
                    Text("Panes that don’t fit in the calendar are hidden.")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Reset to Defaults", action: reset)
                }
            }
        }
    }

    /// The sidebar's contents. A custom To Do height still shows both panes.
    private var sidebar: Binding<Sidebar> {
        Binding(
            get: {
                switch CalendarLayout(rawValue: layout) ?? .normal {
                case .normal, .custom: .both
                case .toDo: .toDo
                case .rightNow: .rightNow
                }
            },
            set: { newValue in
                switch newValue {
                case .both:
                    if layout != CalendarLayout.custom.rawValue { layout = CalendarLayout.normal.rawValue }
                case .toDo: layout = CalendarLayout.toDo.rawValue
                case .rightNow: layout = CalendarLayout.rightNow.rawValue
                }
            })
    }

    /// A pane height of 0 hides the pane; turning it back on restores its default height.
    private func shows(_ height: Binding<Double>, restoring defaultHeight: Double) -> Binding<Bool> {
        Binding(
            get: { height.wrappedValue > 0 },
            set: { height.wrappedValue = $0 ? defaultHeight : 0 })
    }

    /// Choosing a To Do height switches from the even split to a custom one.
    private func customLayout(_ value: Binding<Double>) -> Binding<Double> {
        Binding(
            get: { value.wrappedValue },
            set: {
                value.wrappedValue = $0
                layout = CalendarLayout.custom.rawValue
            })
    }

    private func reset() {
        let defaults = UserDefaults.standard
        for key in [
            DefaultsKey.calendarLayout, DefaultsKey.infoWidth, DefaultsKey.dateHeight, DefaultsKey.toDoHeight,
            DefaultsKey.allDayHeight,
        ] {
            defaults.removeObject(forKey: key)
        }
    }

    private func sizeSlider(
        _ title: LocalizedStringKey, value: Binding<Double>, range: ClosedRange<Double>, from: LocalizedStringKey,
        to: LocalizedStringKey
    ) -> some View {
        // No step: stepped sliders draw a tick mark for every step. Values are rounded to whole points instead.
        Slider(
            value: Binding(get: { value.wrappedValue }, set: { value.wrappedValue = $0.rounded() }), in: range
        ) {
            Text(title)
        } minimumValueLabel: {
            Text(from).font(.caption).foregroundStyle(.secondary)
        } maximumValueLabel: {
            Text(to).font(.caption).foregroundStyle(.secondary)
        }
    }

    /// The calendar's size on its screen, without its padding.
    private var calendarSize: CGSize {
        _ = size  // Recompute when the calendar size changes.
        guard let screen = DesktopWindowController.targetScreen() else { return CGSize(width: 1000, height: 700) }
        let frame = DesktopWindowController.frame(on: screen)
        return CGSize(
            width: max(frame.width - CalendarView.padding * 2, 1),
            height: max(frame.height - CalendarView.padding * 2, 1))
    }

    private var panes: PaneLayout {
        var metrics = PaneLayout.Metrics()
        metrics.infoWidth = infoWidth
        metrics.dateHeight = dateHeight
        metrics.toDoHeight = toDoHeight
        metrics.allDayHeight = allDayHeight
        return PaneLayout(
            size: calendarSize, layout: CalendarLayout(rawValue: layout) ?? .normal,
            calendarSize: CalendarSize(rawValue: size) ?? .normal, metrics: metrics)
    }
}

/// A miniature of the calendar, showing which panes are visible and how large they are.
private struct LayoutPreview: View {
    let panes: PaneLayout
    let size: CGSize

    var body: some View {
        GeometryReader { geometry in
            // Leave room for the padding around the miniature.
            let scale = min((geometry.size.width - 12) / size.width, (geometry.size.height - 12) / size.height)
            let width = size.width * scale
            let height = size.height * scale
            ZStack(alignment: .topLeading) {
                if panes.showsInfo {
                    let toDoY = panes.dateHeight > 0 ? panes.dateHeight + PaneLayout.spacingAfterDate : 0
                    let rightNowY = toDoY + (panes.toDoHeight > 0 ? panes.toDoHeight + PaneLayout.spacingAfterToDo : 0)
                    if panes.dateHeight > 0 {
                        pane("calendar", x: 0, y: 0, width: panes.infoWidth, height: panes.dateHeight, scale: scale)
                    }
                    if panes.toDoHeight > 0 {
                        pane(
                            "checklist", x: 0, y: toDoY, width: panes.infoWidth, height: panes.toDoHeight, scale: scale)
                    }
                    if panes.rightNowHeight > 0 {
                        pane(
                            "clock", x: 0, y: rightNowY, width: panes.infoWidth, height: panes.rightNowHeight,
                            scale: scale)
                    }
                }
                if panes.showsWeek {
                    let x = panes.showsInfo ? panes.infoWidth + PaneLayout.spacingAfterInfo : 0
                    pane(
                        "calendar.day.timeline.left", x: x, y: 0, width: panes.weekWidth, height: size.height,
                        scale: scale)
                }
            }
            .frame(width: width, height: height, alignment: .topLeading)
            .padding(6)
            .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .animation(.smooth(duration: 0.25), value: panes)
    }

    private func pane(_ symbol: String, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, scale: CGFloat)
        -> some View
    {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(Color.accentColor.opacity(0.18))
            .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).strokeBorder(Color.accentColor.opacity(0.4)))
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: max(width * scale, 0), height: max(height * scale, 0))
            .offset(x: x * scale, y: y * scale)
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
                        let pane = store.eventAccess == .denied ? "Privacy_Calendars" : "Privacy_Reminders"
                        open("x-apple.systempreferences:com.apple.preference.security?\(pane)")
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
