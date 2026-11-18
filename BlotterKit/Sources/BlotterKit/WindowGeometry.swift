import Foundation

/// Computes where the calendar window sits on a screen.
public enum WindowGeometry {
    /// Space kept between a non-custom calendar and the edges of the screen's visible frame.
    public static let margin: CGFloat = 14
    public static let narrowSize = CGSize(width: 308, height: 718)
    public static let normalMinimumSize = CGSize(width: 950, height: 718)
    /// Smallest custom frame, in points.
    public static let minimumCustomSize = CGSize(width: 230, height: 100)
    /// Custom frame used until the user picks one: the normal size, top left.
    public static let defaultCustomFactors = CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5)

    /// Frame of the calendar window, in the same bottom-left-origin coordinates as `visibleFrame`.
    ///
    /// - Parameters:
    ///   - visibleFrame: The screen's visible frame (excluding the menu bar and Dock).
    ///   - customFactors: For `.custom`, the frame as fractions (0–1) of `visibleFrame`, bottom-left origin.
    public static func frame(
        in visibleFrame: CGRect,
        size: CalendarSize,
        position: CalendarPosition,
        customFactors: CGRect = defaultCustomFactors
    ) -> CGRect {
        if size == .custom {
            let factors = sanitized(customFactors)
            return CGRect(
                x: visibleFrame.minX + factors.minX * visibleFrame.width,
                y: visibleFrame.minY + factors.minY * visibleFrame.height,
                width: factors.width * visibleFrame.width,
                height: factors.height * visibleFrame.height
            )
        }

        let area = visibleFrame.insetBy(dx: margin, dy: margin)
        var windowSize: CGSize
        switch size {
        case .narrow:
            windowSize = CGSize(width: narrowSize.width, height: min(narrowSize.height, area.height))
        case .normal:
            windowSize = CGSize(
                width: max(normalMinimumSize.width, area.width / 2),
                height: max(normalMinimumSize.height, area.height / 2)
            )
        case .full, .custom:
            windowSize = area.size
        }
        // Small screens: never spill outside the visible frame.
        windowSize.width = min(windowSize.width, area.width)
        windowSize.height = min(windowSize.height, area.height)

        let x: CGFloat
        switch position.column {
        case 0: x = 0
        case 1: x = ((area.width - windowSize.width) / 2).rounded(.down)
        default: x = area.width - windowSize.width
        }

        let y: CGFloat
        switch position.row {
        case 0: y = area.height - windowSize.height
        case 1: y = (area.height - windowSize.height) / 2
        default: y = 0
        }

        return CGRect(origin: CGPoint(x: area.minX + x, y: area.minY + y), size: windowSize)
    }

    /// Converts a window frame into custom factors relative to `visibleFrame`, the inverse of `frame(in:...)`.
    public static func customFactors(for frame: CGRect, in visibleFrame: CGRect) -> CGRect {
        guard visibleFrame.width > 0, visibleFrame.height > 0 else { return defaultCustomFactors }
        return sanitized(
            CGRect(
                x: (frame.minX - visibleFrame.minX) / visibleFrame.width,
                y: (frame.minY - visibleFrame.minY) / visibleFrame.height,
                width: frame.width / visibleFrame.width,
                height: frame.height / visibleFrame.height
            ))
    }

    /// Clamps factors into the unit square; an empty or invalid rect falls back to the default.
    public static func sanitized(_ factors: CGRect) -> CGRect {
        guard factors.width.isFinite, factors.height.isFinite, factors.width > 0, factors.height > 0 else {
            return defaultCustomFactors
        }
        let width = min(factors.width, 1)
        let height = min(factors.height, 1)
        return CGRect(
            x: min(max(factors.minX, 0), 1 - width),
            y: min(max(factors.minY, 0), 1 - height),
            width: width,
            height: height
        )
    }
}
