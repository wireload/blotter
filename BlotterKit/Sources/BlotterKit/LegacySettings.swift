import Foundation

/// Conversions from settings written by Blotter 2.x.
public enum LegacySettings {
    /// Calendars hidden in Blotter 2.x.
    ///
    /// 2.x stored `{storeID: {calendarID: {isUsedForEvents, isUsedForReminders, IsEnabled}}}`. A calendar is hidden
    /// for events (or reminders) when it is disabled or not used for them. Missing flags count as shown, as in 2.x.
    public static func hiddenCalendars(from stores: [String: [String: [String: Any]]]) -> (
        events: Set<String>, reminders: Set<String>
    ) {
        var events = Set<String>()
        var reminders = Set<String>()
        for calendars in stores.values {
            for (id, flags) in calendars {
                let enabled = (flags["IsEnabled"] as? Bool) ?? true
                if !enabled || (flags["isUsedForEvents"] as? Bool) == false {
                    events.insert(id)
                }
                if !enabled || (flags["isUsedForReminders"] as? Bool) == false {
                    reminders.insert(id)
                }
            }
        }
        return (events, reminders)
    }
}
