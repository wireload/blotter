import Foundation
import Testing

@testable import BlotterKit

private let gmt: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
}()

/// 1970-01-01 plus the given day and hour offsets, in GMT.
private func moment(day: Int, hour: Int = 0) -> Date {
    Date(timeIntervalSince1970: TimeInterval(day * 86_400 + hour * 3_600))
}

@Suite struct DateRangeTests {
    @Test func normalisesReversedDates() {
        let range = DateRange(start: moment(day: 2), end: moment(day: 1))
        #expect(range.start == moment(day: 1))
        #expect(range.end == moment(day: 2))
    }

    @Test func emptyRange() {
        #expect(DateRange(start: moment(day: 1), end: moment(day: 1)).isEmpty)
        #expect(!DateRange(start: moment(day: 1), end: moment(day: 2)).isEmpty)
    }

    @Test func unionCoversGap() {
        let a = DateRange(start: moment(day: 1), end: moment(day: 2))
        let b = DateRange(start: moment(day: 3), end: moment(day: 4))
        #expect(a.union(b) == DateRange(start: moment(day: 1), end: moment(day: 4)))
        #expect(b.union(a) == DateRange(start: moment(day: 1), end: moment(day: 4)))
    }

    @Test func positionOfDate() {
        let range = DateRange(start: moment(day: 1), end: moment(day: 2))
        #expect(range.position(of: moment(day: 0)) == .earlier)
        #expect(range.position(of: moment(day: 1)) == .within)
        #expect(range.position(of: moment(day: 1, hour: 12)) == .within)
        #expect(range.position(of: moment(day: 2)) == .later)
        #expect(range.position(of: moment(day: 3)) == .later)
    }

    @Test func intersects() {
        let range = DateRange(start: moment(day: 1), end: moment(day: 2))
        let touching = DateRange(start: moment(day: 2), end: moment(day: 3))
        let overlapping = DateRange(start: moment(day: 1, hour: 12), end: moment(day: 3))
        let emptyAtStart = DateRange(start: moment(day: 1), end: moment(day: 1))
        let emptyAtEnd = DateRange(start: moment(day: 2), end: moment(day: 2))

        #expect(!range.intersects(touching))
        #expect(!touching.intersects(range))
        #expect(range.intersects(overlapping))
        #expect(overlapping.intersects(range))
        #expect(range.intersects(emptyAtStart))
        #expect(emptyAtStart.intersects(range))
        #expect(!range.intersects(emptyAtEnd))
    }

    @Test func intersectionPositions() {
        let r = DateRange(start: moment(day: 2), end: moment(day: 4))

        // Disjoint.
        #expect(r.intersection(with: DateRange(start: moment(day: 0), end: moment(day: 1))) == (false, .earlier))
        #expect(r.intersection(with: DateRange(start: moment(day: 0), end: moment(day: 2))) == (false, .earlier))
        #expect(r.intersection(with: DateRange(start: moment(day: 5), end: moment(day: 6))) == (false, .later))
        #expect(r.intersection(with: DateRange(start: moment(day: 4), end: moment(day: 6))) == (false, .later))

        // { [ } ] — the receiver starts inside other and sticks out at the end.
        #expect(r.intersection(with: DateRange(start: moment(day: 1), end: moment(day: 3))) == (true, .earlier))
        // [ { ] }
        #expect(r.intersection(with: DateRange(start: moment(day: 3), end: moment(day: 5))) == (true, .later))
        // [ ] inside { }
        #expect(r.intersection(with: DateRange(start: moment(day: 1), end: moment(day: 5))) == (true, .within))
        #expect(r.intersection(with: r) == (true, .within))
        // { } inside [ ]
        #expect(
            r.intersection(with: DateRange(start: moment(day: 2, hour: 1), end: moment(day: 3))) == (true, .overlaps))
    }

    @Test(arguments: alignmentCases)
    func alignment(_ testCase: AlignmentCase) {
        let aligned = testCase.range.aligned(to: .day, in: gmt, start: testCase.start, end: testCase.end)
        #expect(aligned == testCase.expected, "\(testCase.range) aligned \(testCase.start)/\(testCase.end)")
    }

    @Test func splitByDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 3_600)!
        let start = calendar.date(byAdding: DateComponents(day: 1, hour: 14), to: moment(day: 0))!
        let end = calendar.date(byAdding: DateComponents(day: 3, hour: 11), to: moment(day: 0))!
        let startDayEnd = calendar.dateInterval(of: .day, for: start)!.end
        let endDayStart = calendar.dateInterval(of: .day, for: end)!.start

        let parts = DateRange(start: start, end: end).split(by: .day, in: calendar)

        #expect(
            parts == [
                DateRange(start: start, end: startDayEnd),
                DateRange(start: startDayEnd, end: endDayStart),
                DateRange(start: endDayStart, end: end),
            ])
    }

    @Test func splitEmptyRange() {
        let empty = DateRange(start: moment(day: 1, hour: 5), end: moment(day: 1, hour: 5))
        #expect(empty.split(by: .day, in: gmt) == [empty])
    }
}

struct AlignmentCase: Sendable, CustomTestStringConvertible {
    let range: DateRange
    let start: DateRange.Alignment
    let end: DateRange.Alignment
    let expected: DateRange

    var testDescription: String { "\(range) \(start)/\(end)" }
}

/// Named ranges on 1970-01-02 ("start day") and 1970-01-03 ("end day"), in GMT.
private enum r {
    static let startDayFirst = DateRange(start: moment(day: 1), end: moment(day: 1))
    static let startDayLast = DateRange(start: moment(day: 2), end: moment(day: 2))
    static let startDay = DateRange(start: moment(day: 1), end: moment(day: 2))
    static let startDayAM = DateRange(start: moment(day: 1), end: moment(day: 1, hour: 10))
    static let startDayAMMoment = DateRange(start: moment(day: 1, hour: 10), end: moment(day: 1, hour: 10))
    static let startDayAMPM = DateRange(start: moment(day: 1, hour: 10), end: moment(day: 1, hour: 14))
    static let startDayPMMoment = DateRange(start: moment(day: 1, hour: 14), end: moment(day: 1, hour: 14))
    static let startDayPM = DateRange(start: moment(day: 1, hour: 14), end: moment(day: 2))
    static let endDay = DateRange(start: moment(day: 2), end: moment(day: 3))
    static let twoDays = DateRange(start: moment(day: 1), end: moment(day: 3))
    static let spentAM = DateRange(start: moment(day: 1), end: moment(day: 2, hour: 10))
    static let spentPM = DateRange(start: moment(day: 1), end: moment(day: 2, hour: 14))
    static let remainingAM = DateRange(start: moment(day: 1, hour: 10), end: moment(day: 3))
    static let remainingPM = DateRange(start: moment(day: 1, hour: 14), end: moment(day: 3))
    static let amAM = DateRange(start: moment(day: 1, hour: 10), end: moment(day: 2, hour: 10))
    static let amPM = DateRange(start: moment(day: 1, hour: 10), end: moment(day: 2, hour: 14))
    static let pmAM = DateRange(start: moment(day: 1, hour: 14), end: moment(day: 2, hour: 10))
    static let pmPM = DateRange(start: moment(day: 1, hour: 14), end: moment(day: 2, hour: 14))
}

/// Exhaustive start/end alignment grid, ported from the Objective-C WLDateRange test suite.
let alignmentCases: [AlignmentCase] = alignmentGrid.map {
    AlignmentCase(range: $0.0, start: $0.1, end: $0.2, expected: $0.3)
}

private let alignmentGrid: [(DateRange, DateRange.Alignment, DateRange.Alignment, DateRange)] = [
    (r.startDay, .inward, .inward, r.startDay),
    (r.startDay, .inward, .outward, r.startDay),
    (r.startDay, .inward, .nearest, r.startDay),
    (r.startDay, .outward, .inward, r.startDay),
    (r.startDay, .outward, .outward, r.startDay),
    (r.startDay, .outward, .nearest, r.startDay),
    (r.startDay, .nearest, .inward, r.startDay),
    (r.startDay, .nearest, .outward, r.startDay),
    (r.startDay, .nearest, .nearest, r.startDay),
    (r.startDayFirst, .inward, .inward, r.startDayFirst),
    (r.startDayFirst, .inward, .outward, r.startDayFirst),
    (r.startDayFirst, .inward, .nearest, r.startDayFirst),
    (r.startDayFirst, .outward, .inward, r.startDayFirst),
    (r.startDayFirst, .outward, .outward, r.startDayFirst),
    (r.startDayFirst, .outward, .nearest, r.startDayFirst),
    (r.startDayFirst, .nearest, .inward, r.startDayFirst),
    (r.startDayFirst, .nearest, .outward, r.startDayFirst),
    (r.startDayFirst, .nearest, .nearest, r.startDayFirst),
    (r.startDayAM, .inward, .inward, r.startDayFirst),
    (r.startDayAM, .inward, .outward, r.startDay),
    (r.startDayAM, .inward, .nearest, r.startDayFirst),
    (r.startDayAM, .outward, .inward, r.startDayFirst),
    (r.startDayAM, .outward, .outward, r.startDay),
    (r.startDayAM, .outward, .nearest, r.startDayFirst),
    (r.startDayAM, .nearest, .inward, r.startDayFirst),
    (r.startDayAM, .nearest, .outward, r.startDay),
    (r.startDayAM, .nearest, .nearest, r.startDayFirst),
    (r.startDayAMMoment, .inward, .inward, r.startDay),
    (r.startDayAMMoment, .inward, .outward, r.startDayLast),
    (r.startDayAMMoment, .inward, .nearest, r.startDay),
    (r.startDayAMMoment, .outward, .inward, r.startDayFirst),
    (r.startDayAMMoment, .outward, .outward, r.startDay),
    (r.startDayAMMoment, .outward, .nearest, r.startDayFirst),
    (r.startDayAMMoment, .nearest, .inward, r.startDayFirst),
    (r.startDayAMMoment, .nearest, .outward, r.startDay),
    (r.startDayAMMoment, .nearest, .nearest, r.startDayFirst),
    (r.startDayAMPM, .inward, .inward, r.startDay),
    (r.startDayAMPM, .inward, .outward, r.startDayLast),
    (r.startDayAMPM, .inward, .nearest, r.startDayLast),
    (r.startDayAMPM, .outward, .inward, r.startDayFirst),
    (r.startDayAMPM, .outward, .outward, r.startDay),
    (r.startDayAMPM, .outward, .nearest, r.startDay),
    (r.startDayAMPM, .nearest, .inward, r.startDayFirst),
    (r.startDayAMPM, .nearest, .outward, r.startDay),
    (r.startDayAMPM, .nearest, .nearest, r.startDay),
    (r.startDayPMMoment, .inward, .inward, r.startDay),
    (r.startDayPMMoment, .inward, .outward, r.startDayLast),
    (r.startDayPMMoment, .inward, .nearest, r.startDayLast),
    (r.startDayPMMoment, .outward, .inward, r.startDayFirst),
    (r.startDayPMMoment, .outward, .outward, r.startDay),
    (r.startDayPMMoment, .outward, .nearest, r.startDay),
    (r.startDayPMMoment, .nearest, .inward, r.startDay),
    (r.startDayPMMoment, .nearest, .outward, r.startDayLast),
    (r.startDayPMMoment, .nearest, .nearest, r.startDayLast),
    (r.startDayPM, .inward, .inward, r.startDayLast),
    (r.startDayPM, .inward, .outward, r.startDayLast),
    (r.startDayPM, .inward, .nearest, r.startDayLast),
    (r.startDayPM, .outward, .inward, r.startDay),
    (r.startDayPM, .outward, .outward, r.startDay),
    (r.startDayPM, .outward, .nearest, r.startDay),
    (r.startDayPM, .nearest, .inward, r.startDayLast),
    (r.startDayPM, .nearest, .outward, r.startDayLast),
    (r.startDayPM, .nearest, .nearest, r.startDayLast),
    (r.startDayLast, .inward, .inward, r.startDayLast),
    (r.startDayLast, .inward, .outward, r.startDayLast),
    (r.startDayLast, .inward, .nearest, r.startDayLast),
    (r.startDayLast, .outward, .inward, r.startDayLast),
    (r.startDayLast, .outward, .outward, r.startDayLast),
    (r.startDayLast, .outward, .nearest, r.startDayLast),
    (r.startDayLast, .nearest, .inward, r.startDayLast),
    (r.startDayLast, .nearest, .outward, r.startDayLast),
    (r.startDayLast, .nearest, .nearest, r.startDayLast),
    (r.twoDays, .inward, .inward, r.twoDays),
    (r.twoDays, .inward, .outward, r.twoDays),
    (r.twoDays, .inward, .nearest, r.twoDays),
    (r.twoDays, .outward, .inward, r.twoDays),
    (r.twoDays, .outward, .outward, r.twoDays),
    (r.twoDays, .outward, .nearest, r.twoDays),
    (r.twoDays, .nearest, .inward, r.twoDays),
    (r.twoDays, .nearest, .outward, r.twoDays),
    (r.twoDays, .nearest, .nearest, r.twoDays),
    (r.spentAM, .inward, .inward, r.startDay),
    (r.spentAM, .inward, .outward, r.twoDays),
    (r.spentAM, .inward, .nearest, r.startDay),
    (r.spentAM, .outward, .inward, r.startDay),
    (r.spentAM, .outward, .outward, r.twoDays),
    (r.spentAM, .outward, .nearest, r.startDay),
    (r.spentAM, .nearest, .inward, r.startDay),
    (r.spentAM, .nearest, .outward, r.twoDays),
    (r.spentAM, .nearest, .nearest, r.startDay),
    (r.spentPM, .inward, .inward, r.startDay),
    (r.spentPM, .inward, .outward, r.twoDays),
    (r.spentPM, .inward, .nearest, r.twoDays),
    (r.spentPM, .outward, .inward, r.startDay),
    (r.spentPM, .outward, .outward, r.twoDays),
    (r.spentPM, .outward, .nearest, r.twoDays),
    (r.spentPM, .nearest, .inward, r.startDay),
    (r.spentPM, .nearest, .outward, r.twoDays),
    (r.spentPM, .nearest, .nearest, r.twoDays),
    (r.remainingAM, .inward, .inward, r.endDay),
    (r.remainingAM, .inward, .outward, r.endDay),
    (r.remainingAM, .inward, .nearest, r.endDay),
    (r.remainingAM, .outward, .inward, r.twoDays),
    (r.remainingAM, .outward, .outward, r.twoDays),
    (r.remainingAM, .outward, .nearest, r.twoDays),
    (r.remainingAM, .nearest, .inward, r.twoDays),
    (r.remainingAM, .nearest, .outward, r.twoDays),
    (r.remainingAM, .nearest, .nearest, r.twoDays),
    (r.remainingPM, .inward, .inward, r.endDay),
    (r.remainingPM, .inward, .outward, r.endDay),
    (r.remainingPM, .inward, .nearest, r.endDay),
    (r.remainingPM, .outward, .inward, r.twoDays),
    (r.remainingPM, .outward, .outward, r.twoDays),
    (r.remainingPM, .outward, .nearest, r.twoDays),
    (r.remainingPM, .nearest, .inward, r.endDay),
    (r.remainingPM, .nearest, .outward, r.endDay),
    (r.remainingPM, .nearest, .nearest, r.endDay),
    (r.amAM, .inward, .inward, r.startDayLast),
    (r.amAM, .inward, .outward, r.endDay),
    (r.amAM, .inward, .nearest, r.startDayLast),
    (r.amAM, .outward, .inward, r.startDay),
    (r.amAM, .outward, .outward, r.twoDays),
    (r.amAM, .outward, .nearest, r.startDay),
    (r.amAM, .nearest, .inward, r.startDay),
    (r.amAM, .nearest, .outward, r.twoDays),
    (r.amAM, .nearest, .nearest, r.startDay),
    (r.amPM, .inward, .inward, r.startDayLast),
    (r.amPM, .inward, .outward, r.endDay),
    (r.amPM, .inward, .nearest, r.endDay),
    (r.amPM, .outward, .inward, r.startDay),
    (r.amPM, .outward, .outward, r.twoDays),
    (r.amPM, .outward, .nearest, r.twoDays),
    (r.amPM, .nearest, .inward, r.startDay),
    (r.amPM, .nearest, .outward, r.twoDays),
    (r.amPM, .nearest, .nearest, r.twoDays),
    (r.pmAM, .inward, .inward, r.startDayLast),
    (r.pmAM, .inward, .outward, r.endDay),
    (r.pmAM, .inward, .nearest, r.startDayLast),
    (r.pmAM, .outward, .inward, r.startDay),
    (r.pmAM, .outward, .outward, r.twoDays),
    (r.pmAM, .outward, .nearest, r.startDay),
    (r.pmAM, .nearest, .inward, r.startDayLast),
    (r.pmAM, .nearest, .outward, r.endDay),
    (r.pmAM, .nearest, .nearest, r.startDayLast),
    (r.pmPM, .inward, .inward, r.startDayLast),
    (r.pmPM, .inward, .outward, r.endDay),
    (r.pmPM, .inward, .nearest, r.endDay),
    (r.pmPM, .outward, .inward, r.startDay),
    (r.pmPM, .outward, .outward, r.twoDays),
    (r.pmPM, .outward, .nearest, r.twoDays),
    (r.pmPM, .nearest, .inward, r.startDayLast),
    (r.pmPM, .nearest, .outward, r.endDay),
    (r.pmPM, .nearest, .nearest, r.endDay),
]
