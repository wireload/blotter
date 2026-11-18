import Foundation

/// Sizes of the panes inside the calendar window: an info column (date, To Do, Right Now) beside the week.
public struct PaneLayout: Equatable, Sendable {
    public static let spacingAfterInfo: CGFloat = 17
    public static let spacingAfterDate: CGFloat = 10
    public static let spacingAfterToDo: CGFloat = 10
    public static let spacingAfterAllDay: CGFloat = 8

    /// User-adjustable sizes and the minimums below which a pane is hidden.
    public struct Metrics: Equatable, Sendable {
        public var infoWidth: CGFloat = 250
        public var dateHeight: CGFloat = 250
        public var toDoHeight: CGFloat = 200
        public var allDayHeight: CGFloat = 110

        public var minimumInfoWidth: CGFloat = 230
        public var minimumDateHeight: CGFloat = 180
        public var minimumToDoHeight: CGFloat = 100
        public var minimumRightNowHeight: CGFloat = 100
        public var minimumWeekWidth: CGFloat = 460
        public var minimumAllDayHeight: CGFloat = 50
        public var minimumTimedHeight: CGFloat = 300

        public init() {}
    }

    public var infoWidth: CGFloat
    public var weekWidth: CGFloat
    public var dateHeight: CGFloat
    public var toDoHeight: CGFloat
    public var rightNowHeight: CGFloat
    public var allDayHeight: CGFloat
    public var timedHeight: CGFloat

    public var showsInfo: Bool { infoWidth > 0 }
    public var showsWeek: Bool { weekWidth > 0 }

    public init(size: CGSize, layout: CalendarLayout, calendarSize: CalendarSize, metrics: Metrics = Metrics()) {
        let defaults = Metrics()

        (infoWidth, weekWidth) = Self.split(
            size.width,
            minimumA: metrics.minimumInfoWidth,
            preferredA: layout == .custom ? metrics.infoWidth : defaults.infoWidth,
            spacing: Self.spacingAfterInfo,
            // A narrow calendar never shows the week.
            minimumB: calendarSize == .narrow ? size.width + 1 : metrics.minimumWeekWidth
        )

        let remainder: CGFloat
        (dateHeight, remainder) = Self.split(
            size.height,
            minimumA: metrics.minimumDateHeight,
            preferredA: metrics.dateHeight,
            spacing: Self.spacingAfterDate,
            minimumB: min(metrics.minimumToDoHeight, metrics.minimumRightNowHeight)
        )

        let preferredToDo: CGFloat
        switch layout {
        case .normal: preferredToDo = max(remainder - Self.spacingAfterToDo, 0) / 2
        case .custom: preferredToDo = metrics.toDoHeight
        case .toDo: preferredToDo = remainder
        case .rightNow: preferredToDo = 0
        }
        (toDoHeight, rightNowHeight) = Self.split(
            remainder,
            minimumA: metrics.minimumToDoHeight,
            preferredA: preferredToDo,
            spacing: Self.spacingAfterToDo,
            minimumB: layout == .toDo ? remainder + 1 : metrics.minimumRightNowHeight
        )

        (allDayHeight, timedHeight) = Self.split(
            size.height,
            minimumA: metrics.minimumAllDayHeight,
            preferredA: metrics.allDayHeight,
            spacing: Self.spacingAfterAllDay,
            minimumB: metrics.minimumTimedHeight
        )
    }

    /// Splits `total` into A, spacing and B, giving A its preferred size first.
    ///
    /// A part smaller than its minimum is hidden (size 0). When B is hidden, A takes all the space.
    static func split(
        _ total: CGFloat,
        minimumA: CGFloat,
        preferredA: CGFloat,
        spacing: CGFloat,
        minimumB: CGFloat
    ) -> (CGFloat, CGFloat) {
        var remaining = max(total, 0)
        var a = min(max(preferredA, 0), remaining)
        let showsA = a >= minimumA && a > 0
        if showsA {
            remaining -= a
        } else {
            a = 0
        }

        var b = showsA ? remaining - spacing : remaining
        if b < minimumB || b <= 0 {
            b = 0
            if showsA { a += remaining }
        }
        return (a, b)
    }
}
