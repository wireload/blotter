import Foundation

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

/// Arranges overlapping timed events of one day side by side.
///
/// The algorithm is Blotter's original one:
/// 1. **Rows.** Walking events in start order, an event that starts before the current row ends joins that row;
///    otherwise it opens a new row. Rows never overlap each other.
/// 2. **Columns.** Within a row, columns are filled greedily: each new column takes the first unplaced event, then
///    every later unplaced event that starts at or after the column's current bottom.
/// 3. **Widening.** An event stretches over the columns to its right until it meets one with an overlapping event.
public enum EventLayout {
    /// A vertical extent to lay out, in any unit (for example points or hours).
    public struct Segment<ID: Hashable & Sendable>: Hashable, Sendable {
        public var id: ID
        public var top: Double
        public var bottom: Double

        public init(id: ID, top: Double, bottom: Double) {
            self.id = id
            self.top = top
            self.bottom = max(bottom, top)
        }

        func overlaps(_ other: Segment) -> Bool {
            top < other.bottom && other.top < bottom
        }
    }

    public struct Placement<ID: Hashable & Sendable>: Hashable, Sendable {
        public var segment: Segment<ID>
        /// Index of the row (cluster of transitively overlapping events) this event belongs to.
        public var row: Int
        /// Leftmost column the event occupies.
        public var column: Int
        /// Number of columns the event spans, at least 1.
        public var span: Int
        /// Number of columns in the event's row.
        public var columnCount: Int

        /// Horizontal extent within `width`, leaving `gap` between columns.
        ///
        /// Column widths are whole points; leftover points go one each to the first columns.
        public func horizontalExtent(width: CGFloat, gap: CGFloat) -> (x: CGFloat, width: CGFloat) {
            let available = max(width - gap * CGFloat(columnCount - 1), 0)
            let base = (available / CGFloat(columnCount)).rounded(.down)
            let extra = Int(available - base * CGFloat(columnCount))

            func columnWidth(_ index: Int) -> CGFloat { base + (index < extra ? 1 : 0) }

            var x: CGFloat = 0
            for index in 0..<column { x += columnWidth(index) + gap }
            var w: CGFloat = 0
            for index in column..<(column + span) { w += columnWidth(index) }
            w += gap * CGFloat(span - 1)
            return (x, min(w, width - x))
        }

        /// Whether the event is alone in its row.
        public var isAlone: Bool { columnCount == 1 }
    }

    /// Places `segments`, which should be sorted by start (ties broken by a stable key such as the event ID).
    public static func place<ID>(_ segments: [Segment<ID>], maximumColumns: Int = .max) -> [Placement<ID>] {
        let maximumColumns = max(maximumColumns, 1)

        // Step 1: rows.
        var rows: [[Segment<ID>]] = []
        var rowBottom = -Double.infinity
        for segment in segments {
            if segment.top < rowBottom, !rows.isEmpty {
                rows[rows.count - 1].append(segment)
                rowBottom = max(rowBottom, segment.bottom)
            } else {
                rows.append([segment])
                rowBottom = segment.bottom
            }
        }

        var placements: [Placement<ID>] = []
        for (rowIndex, row) in rows.enumerated() {
            // Step 2: columns.
            var remaining = row
            var columns: [[Segment<ID>]] = []
            while !remaining.isEmpty, columns.count < maximumColumns {
                var column = [remaining.removeFirst()]
                var columnBottom = column[0].bottom
                remaining.removeAll { segment in
                    guard columnBottom <= segment.top else { return false }
                    column.append(segment)
                    columnBottom = segment.bottom
                    return true
                }
                columns.append(column)
            }
            for (index, segment) in remaining.enumerated() {
                columns[index % columns.count].append(segment)
            }

            // Step 3: widening.
            for (columnIndex, column) in columns.enumerated() {
                for segment in column {
                    var span = 1
                    while columnIndex + span < columns.count,
                        !columns[columnIndex + span].contains(where: { $0.overlaps(segment) })
                    {
                        span += 1
                    }
                    placements.append(
                        Placement(
                            segment: segment, row: rowIndex, column: columnIndex, span: span,
                            columnCount: columns.count))
                }
            }
        }
        return placements
    }
}
