import Foundation

/// A half-open range of time, `[start, end)`.
///
/// The start is never later than the end: initialising with reversed dates swaps them.
public struct DateRange: Hashable, Sendable {
    public let start: Date
    public let end: Date

    public init(start: Date, end: Date) {
        if start <= end {
            self.start = start
            self.end = end
        } else {
            self.start = end
            self.end = start
        }
    }

    public init(_ interval: DateInterval) {
        self.init(start: interval.start, end: interval.end)
    }

    public var isEmpty: Bool { start == end }

    public var duration: TimeInterval { end.timeIntervalSince(start) }

    /// Position of a date or a range relative to the receiver.
    public enum Position: Sendable {
        case earlier
        case within
        case later
        case overlaps
    }

    /// Position of `date` relative to the receiver.
    ///
    /// The start date lies within (even for an empty range); the end date of a non-empty range lies later.
    public func position(of date: Date) -> Position {
        if date < start { return .earlier }
        if date == start || date < end { return .within }
        return .later
    }

    /// Whether `other` shares any moment with the receiver.
    ///
    /// Ranges that only touch at one end do not intersect, but an empty range at the start of the receiver does.
    public func intersects(_ other: DateRange) -> Bool {
        position(of: other.start) != .later && other.position(of: start) != .later
    }

    /// Whether `other` intersects the receiver, and where the receiver lies relative to `other`.
    ///
    /// `[]` is the receiver, `{}` is `other`.
    /// - Intersecting: `.earlier` for `{ [ } ]`; `.overlaps` when `[]` covers `{}` and sticks out;
    ///   `.within` when `[]` lies inside `{}`; `.later` for `[ { ] }`.
    /// - Not intersecting: `.earlier` for `{ } [ ]`; `.later` for `[ ] { }` (including `[ {] }`).
    public func intersection(with other: DateRange) -> (intersects: Bool, position: Position) {
        let sameStart = start == other.start

        if start >= other.end && !sameStart {
            return (false, .earlier)
        }
        if end <= other.start && !sameStart {
            return (false, .later)
        }

        if start < other.start && end < other.end {
            return (true, .later)
        } else if start > other.start && end > other.end {
            return (true, .earlier)
        } else if start >= other.start && end <= other.end {
            return (true, .within)
        } else {
            return (true, .overlaps)
        }
    }

    /// The smallest range covering both the receiver and `other`, including any gap between them.
    public func union(_ other: DateRange) -> DateRange {
        DateRange(start: min(start, other.start), end: max(end, other.end))
    }

    // MARK: Alignment

    /// How an end of the range snaps to a calendar unit boundary.
    public enum Alignment: Sendable, CaseIterable {
        /// Towards the other end of the range.
        case inward
        /// Away from the other end of the range.
        case outward
        /// Towards the nearest boundary; ties go outward.
        case nearest
    }

    /// Snaps the start and end to boundaries of `component` in `calendar`.
    ///
    /// An end that already lies on a boundary is left alone. The result is normalised, so aligning both ends inward
    /// within a single unit swaps them: `{10:00, 14:00}` aligned inward by day becomes `{00:00, 24:00}`.
    public func aligned(
        to component: Calendar.Component,
        in calendar: Calendar,
        start startAlignment: Alignment,
        end endAlignment: Alignment
    ) -> DateRange {
        guard let startUnit = calendar.dateInterval(of: component, for: start),
            let endUnit = calendar.dateInterval(of: component, for: end)
        else {
            preconditionFailure("\(calendar) cannot align \(self) to \(component)")
        }

        func snap(_ date: Date, outward: Date, inward: Date, alignment: Alignment) -> Date {
            if date == outward || date == inward { return date }
            switch alignment {
            case .inward: return inward
            case .outward: return outward
            case .nearest:
                return abs(date.timeIntervalSince(outward)) <= abs(date.timeIntervalSince(inward)) ? outward : inward
            }
        }

        return DateRange(
            start: snap(start, outward: startUnit.start, inward: startUnit.end, alignment: startAlignment),
            end: snap(end, outward: endUnit.end, inward: endUnit.start, alignment: endAlignment)
        )
    }

    /// Snaps both ends with the same alignment.
    public func aligned(to component: Calendar.Component, in calendar: Calendar, _ alignment: Alignment) -> DateRange {
        aligned(to: component, in: calendar, start: alignment, end: alignment)
    }

    // MARK: Splitting

    /// Splits the receiver at every boundary of `component`. The parts are sorted and cover the receiver exactly.
    ///
    /// An empty range produces a single empty part.
    public func split(by component: Calendar.Component, in calendar: Calendar) -> [DateRange] {
        var parts: [DateRange] = []
        var partStart = start
        var unitEnd: Date

        repeat {
            guard let unit = calendar.dateInterval(of: component, for: partStart) else {
                preconditionFailure("\(calendar) cannot split \(self) by \(component)")
            }
            unitEnd = unit.end
            parts.append(DateRange(start: partStart, end: min(unitEnd, end)))
            partStart = unitEnd
        } while end > unitEnd

        return parts
    }
}

extension DateRange: CustomStringConvertible {
    public var description: String { "{\(start), \(end)}" }
}
