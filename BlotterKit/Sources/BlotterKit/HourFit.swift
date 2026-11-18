import Foundation

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// Chooses which hours of a day are visible and how tall an hour is, so that every event fits and stays readable.
public struct HourFit: Equatable, Sendable {
    /// First visible hour (may be fractional).
    public var startHour: Double
    /// Height of one hour, in points.
    public var hourHeight: CGFloat

    /// Last visible hour for a given available height.
    public func endHour(height: CGFloat) -> Double {
        startHour + Double(height / hourHeight)
    }

    /// Vertical position of `hour`, relative to the top of the visible area.
    public func offset(ofHour hour: Double) -> CGFloat {
        CGFloat(hour - startHour) * hourHeight
    }

    public init(startHour: Double, hourHeight: CGFloat) {
        self.startHour = startHour
        self.hourHeight = hourHeight
    }

    /// An event to fit: its start and end in hours since midnight, and the height it needs to be readable.
    public struct Item: Sendable {
        public var startHour: Double
        public var endHour: Double
        public var minimumHeight: CGFloat

        public init(startHour: Double, endHour: Double, minimumHeight: CGFloat) {
            self.startHour = startHour
            self.endHour = endHour
            self.minimumHeight = minimumHeight
        }
    }

    /// Fits `items` into `height` points.
    ///
    /// The visible hours cover `workingHours` and every event (whole hours). The hour height is then reduced, if
    /// needed, so that an event starting late still has room for its minimum height above the bottom edge; any
    /// space this frees extends the visible range downwards, up to the end of the day.
    public static func fit(
        _ items: [Item],
        height: CGFloat,
        workingHours: ClosedRange<Double> = 9...17,
        hoursInDay: Double = 24
    ) -> HourFit {
        guard height > 0, height.isFinite, hoursInDay > 0 else {
            return HourFit(startHour: min(max(workingHours.lowerBound, 0), max(hoursInDay - 1, 0)), hourHeight: 1)
        }

        var start = workingHours.lowerBound
        var end = workingHours.upperBound
        for item in items {
            start = min(start, item.startHour.rounded(.down))
            end = max(end, item.endHour.rounded(.up))
        }
        // At least one visible hour, inside the day.
        start = min(max(start, 0), hoursInDay - 1)
        end = min(max(end, start + 1), hoursInDay)

        var hourHeight = height / CGFloat(end - start)
        for item in items where item.startHour > start {
            let room = height - item.minimumHeight
            guard room > 0 else { continue }
            hourHeight = min(hourHeight, room / CGFloat(item.startHour - start))
        }
        // Never show more than the whole day. If that is not enough for every event, show the whole day.
        let wholeDay = height / CGFloat(hoursInDay)
        if hourHeight <= wholeDay {
            return HourFit(startHour: 0, hourHeight: wholeDay)
        }

        // If the visible range now runs past the end of the day, show earlier hours instead — but only as far as
        // every event keeps its minimum height above the bottom edge. Any remaining space stays empty below midnight.
        let visibleHours = Double(height / hourHeight)
        if start + visibleHours > hoursInDay {
            var lowestBottom: CGFloat = 0
            for item in items {
                let top = CGFloat(item.startHour - start) * hourHeight
                let bottom = CGFloat(item.endHour - start) * hourHeight
                lowestBottom = max(lowestBottom, top + item.minimumHeight, bottom)
            }
            let slackHours = Double(max(height - lowestBottom, 0) / hourHeight)
            start = max(hoursInDay - visibleHours, start - slackHours, 0)
        }
        return HourFit(startHour: start, hourHeight: hourHeight)
    }
}
