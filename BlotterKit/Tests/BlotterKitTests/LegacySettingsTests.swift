import Foundation
import Testing

@testable import BlotterKit

@Suite struct LegacySettingsTests {
    @Test func hiddenCalendars() {
        let stores: [String: [String: [String: Any]]] = [
            "store": [
                "work": ["isUsedForEvents": true, "isUsedForReminders": true, "IsEnabled": true],
                "birthdays": ["isUsedForEvents": false, "isUsedForReminders": true, "IsEnabled": true],
                "groceries": ["isUsedForEvents": true, "isUsedForReminders": false, "IsEnabled": true],
                "old": ["isUsedForEvents": true, "isUsedForReminders": true, "IsEnabled": false],
                "partial": ["isUsedForEvents": true],
            ]
        ]

        let hidden = LegacySettings.hiddenCalendars(from: stores)

        #expect(hidden.events == ["birthdays", "old"])
        #expect(hidden.reminders == ["groceries", "old"])
    }

    @Test func emptySelection() {
        let hidden = LegacySettings.hiddenCalendars(from: [:])
        #expect(hidden.events.isEmpty && hidden.reminders.isEmpty)
    }
}
