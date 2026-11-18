import Foundation
import Testing

@testable import BlotterKit

@Suite struct EventLayoutTests {
    typealias Segment = EventLayout.Segment<String>

    private func place(_ segments: [(String, Double, Double)]) -> [String: EventLayout.Placement<String>] {
        let placements = EventLayout.place(segments.map { Segment(id: $0.0, top: $0.1, bottom: $0.2) })
        return Dictionary(uniqueKeysWithValues: placements.map { ($0.segment.id, $0) })
    }

    /// The example drawn in the original implementation's comments.
    @Test func originalExample() {
        let p = place([
            ("a", 0, 20),
            ("b", 2, 5),
            ("c", 7, 12),
            ("d", 10, 20),
            ("e", 21, 29),
            ("f", 22, 26),
        ])

        #expect(p["a"]!.row == 0 && p["a"]!.column == 0 && p["a"]!.columnCount == 3)
        // b and c share column 1; d needs column 2 because it overlaps c.
        #expect(p["b"]!.column == 1 && p["c"]!.column == 1 && p["d"]!.column == 2)
        // b does not overlap anything in column 2, so it widens over it; c does overlap d.
        #expect(p["b"]!.span == 2)
        #expect(p["c"]!.span == 1)
        #expect(p["a"]!.span == 1)

        #expect(p["e"]!.row == 1 && p["e"]!.column == 0 && p["e"]!.columnCount == 2)
        #expect(p["f"]!.column == 1 && p["f"]!.span == 1)
    }

    @Test func eventsTouchingEndToStartDoNotOverlap() {
        let p = place([("a", 0, 1), ("b", 1, 2)])
        #expect(p["a"]!.row == 0 && p["b"]!.row == 1)
        #expect(p["a"]!.isAlone && p["b"]!.isAlone)
    }

    @Test func identicalEventsGetSeparateColumns() {
        let p = place([("a", 1, 2), ("b", 1, 2), ("c", 1, 2)])
        #expect(Set(p.values.map(\.column)) == [0, 1, 2])
        #expect(p.values.allSatisfy { $0.span == 1 && $0.columnCount == 3 })
    }

    @Test func maximumColumnsWrapsLeftovers() {
        let p = place([("a", 0, 4), ("b", 0, 4), ("c", 0, 4)].map { $0 }).count
        #expect(p == 3)
        let limited = EventLayout.place(
            [
                Segment(id: "a", top: 0, bottom: 4), Segment(id: "b", top: 0, bottom: 4),
                Segment(id: "c", top: 0, bottom: 4),
            ],
            maximumColumns: 2)
        #expect(limited.map(\.columnCount) == [2, 2, 2])
        #expect(limited.first { $0.segment.id == "c" }!.column == 0)
    }

    @Test func horizontalExtentDistributesRemainder() {
        let placement = EventLayout.Placement(
            segment: Segment(id: "x", top: 0, bottom: 1), row: 0, column: 0, span: 1, columnCount: 3)
        // 100 - 2*2 gaps = 96 → 32 each.
        #expect(placement.horizontalExtent(width: 100, gap: 2) == (0, 32))

        var second = placement
        second.column = 1
        second.span = 2
        // 101 - 4 = 97 → 32, 32, 32 + 1 extra to column 0: widths 33, 32, 32.
        let extent = second.horizontalExtent(width: 101, gap: 2)
        #expect(extent.x == 35)
        #expect(extent.width == 66)
    }
}
