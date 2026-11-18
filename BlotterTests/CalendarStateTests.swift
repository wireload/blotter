import Foundation
import Testing

@testable import Blotter

@MainActor
@Suite struct CalendarStateTests {
    @Test func navigatingForwardChangesTheWeekImmediately() {
        let state = CalendarState()
        state.navigate(to: 2)
        #expect(state.weekOffset == 2)
        #expect(state.lastNavigationWasForward)
    }

    @Test func reversingCommitsTheDirectionBeforeTheWeek() async throws {
        let state = CalendarState()
        state.navigate(to: 1)
        state.navigate(to: 0)
        // The direction flips first; the week follows on the next run loop pass.
        #expect(!state.lastNavigationWasForward)
        #expect(state.weekOffset == 1)
        try await Task.sleep(for: .milliseconds(100))
        #expect(state.weekOffset == 0)
    }

    @Test func bringToFrontAndBack() {
        let state = CalendarState()
        var changes = 0
        state.onPresentationChange = { changes += 1 }
        state.bringToFront()
        #expect(state.presentation == .front)
        state.sendToBack()
        state.sendToBack()
        #expect(state.presentation == .desktop)
        #expect(changes == 2)
    }
}
