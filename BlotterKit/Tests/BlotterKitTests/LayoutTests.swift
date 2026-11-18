import Foundation
import Testing

@testable import BlotterKit

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

@Suite struct WindowGeometryTests {
    let screen = CGRect(x: 0, y: 0, width: 2000, height: 1200)

    @Test func normalTopLeft() {
        let frame = WindowGeometry.frame(in: screen, size: .normal, position: .topLeft)
        #expect(frame == CGRect(x: 14, y: 1200 - 14 - 718, width: 986, height: 718))
    }

    @Test func narrowCenteredBottom() {
        let frame = WindowGeometry.frame(in: screen, size: .narrow, position: .bottomCenter)
        #expect(frame.size == CGSize(width: 308, height: 718))
        #expect(frame.minX == 14 + ((1972 - 308) / 2).rounded(.down))
        #expect(frame.minY == 14)
    }

    @Test func fullCoversInsetArea() {
        let frame = WindowGeometry.frame(in: screen, size: .full, position: .bottomRight)
        #expect(frame == screen.insetBy(dx: 14, dy: 14))
    }

    @Test func neverExceedsSmallScreens() {
        let small = CGRect(x: 0, y: 0, width: 800, height: 600)
        let frame = WindowGeometry.frame(in: small, size: .normal, position: .center)
        #expect(small.insetBy(dx: 14, dy: 14).contains(frame))
    }

    @Test func customRoundTrips() {
        let factors = CGRect(x: 0.25, y: 0.1, width: 0.5, height: 0.8)
        let frame = WindowGeometry.frame(in: screen, size: .custom, position: .topLeft, customFactors: factors)
        #expect(frame == CGRect(x: 500, y: 120, width: 1000, height: 960))
        #expect(WindowGeometry.customFactors(for: frame, in: screen) == factors)
    }

    @Test func sanitizesInvalidFactors() {
        #expect(WindowGeometry.sanitized(.zero) == WindowGeometry.defaultCustomFactors)
        #expect(
            WindowGeometry.sanitized(CGRect(x: 0.9, y: -1, width: 0.5, height: 2))
                == CGRect(x: 0.5, y: 0, width: 0.5, height: 1))
    }
}

@Suite struct PaneLayoutTests {
    @Test func splitPrefersA() {
        #expect(PaneLayout.split(100, minimumA: 10, preferredA: 30, spacing: 10, minimumB: 20) == (30, 60))
    }

    @Test func splitHidesBWhenTooSmall() {
        #expect(PaneLayout.split(100, minimumA: 10, preferredA: 80, spacing: 10, minimumB: 20) == (100, 0))
    }

    @Test func splitHidesAWhenTooSmall() {
        #expect(PaneLayout.split(100, minimumA: 50, preferredA: 30, spacing: 10, minimumB: 20) == (0, 100))
    }

    @Test func normalLayoutShowsEverything() {
        let layout = PaneLayout(size: CGSize(width: 1000, height: 700), layout: .normal, calendarSize: .normal)
        #expect(layout.infoWidth == 250)
        #expect(layout.weekWidth == CGFloat(1000 - 250 - 17))
        #expect(layout.dateHeight == 250)
        #expect(layout.toDoHeight > 0 && layout.rightNowHeight > 0)
        #expect(layout.dateHeight + 10 + layout.toDoHeight + 10 + layout.rightNowHeight == 700)
    }

    @Test func narrowHidesWeek() {
        let layout = PaneLayout(size: CGSize(width: 280, height: 700), layout: .normal, calendarSize: .narrow)
        #expect(!layout.showsWeek)
        #expect(layout.infoWidth == 280)
    }

    @Test func toDoAndRightNowLayouts() {
        let size = CGSize(width: 1000, height: 700)
        let toDo = PaneLayout(size: size, layout: .toDo, calendarSize: .normal)
        #expect(toDo.rightNowHeight == 0 && toDo.toDoHeight == 700 - 250 - 10)
        let rightNow = PaneLayout(size: size, layout: .rightNow, calendarSize: .normal)
        #expect(rightNow.toDoHeight == 0 && rightNow.rightNowHeight == 700 - 250 - 10)
    }
}

@Suite struct HourFitTests {
    @Test func workingHoursByDefault() {
        let fit = HourFit.fit([], height: 400)
        #expect(fit.startHour == 9)
        #expect(fit.hourHeight == 50)
        #expect(fit.endHour(height: 400) == 17)
    }

    @Test func expandsToCoverEvents() {
        let fit = HourFit.fit([HourFit.Item(startHour: 7.5, endHour: 19.25, minimumHeight: 0)], height: 1300)
        #expect(fit.startHour == 7)
        #expect(fit.hourHeight == 100)
    }

    @Test func shrinksHoursSoLateEventsStayReadable() {
        // A 16:00 event needing 100pt: with 50pt hours it would start at 350 and end past 400.
        let fit = HourFit.fit([HourFit.Item(startHour: 16, endHour: 16.25, minimumHeight: 100)], height: 400)
        #expect(fit.startHour == 9)
        #expect(fit.offset(ofHour: 16) + 100 <= 400)
        #expect(fit.endHour(height: 400) > 17)
    }

    @Test func neverShowsMoreThanADay() {
        let fit = HourFit.fit([HourFit.Item(startHour: 23.5, endHour: 24, minimumHeight: 470)], height: 480)
        #expect(fit.hourHeight == 20)
        #expect(fit.startHour == 0)
    }
}
