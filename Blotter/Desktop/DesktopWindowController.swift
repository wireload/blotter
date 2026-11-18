import AppKit
import BlotterKit
import SwiftUI

/// The borderless window that shows the calendar on the desktop.
///
/// On the desktop it sits just above the wallpaper and below desktop icons, ignores the mouse, and appears on every
/// Space. "Bring to Front" lifts it above other windows on the current Space until it is sent back.
final class DesktopWindowController: NSWindowController {
    /// Called when the user presses Escape while the calendar is in front.
    var onCancel: (() -> Void)?

    private let state: CalendarState
    private var observers: [any NSObjectProtocol] = []
    private var lastFrame: CGRect?

    static let fadeDuration: TimeInterval = 0.25
    static let fadedAlpha: CGFloat = 0.5

    private static let desktopLevel = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 15)
    private static let desktopBehavior: NSWindow.CollectionBehavior = [
        .canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenNone, .fullScreenDisallowsTiling,
    ]
    private static let frontBehavior: NSWindow.CollectionBehavior = [
        .moveToActiveSpace, .ignoresCycle, .fullScreenNone, .fullScreenDisallowsTiling,
    ]

    init(clock: Clock, store: CalendarStore, state: CalendarState) {
        self.state = state

        let window = DesktopWindow(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.isReleasedWhenClosed = false
        window.isRestorable = false
        window.tabbingMode = .disallowed
        window.animationBehavior = .none
        window.appearance = NSAppearance(named: .darkAqua)
        window.level = Self.desktopLevel
        window.collectionBehavior = Self.desktopBehavior
        window.ignoresMouseEvents = true

        let background = NSVisualEffectView()
        background.material = .hudWindow
        background.blendingMode = .behindWindow
        background.state = .active
        background.maskImage = Self.roundedMask(radius: 12)

        let content = NSHostingView(
            rootView: CalendarView()
                .environment(clock)
                .environment(store)
                .environment(state)
        )
        content.sizingOptions = []
        content.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: background.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: background.trailingAnchor),
            content.topAnchor.constraint(equalTo: background.topAnchor),
            content.bottomAnchor.constraint(equalTo: background.bottomAnchor),
        ])
        window.contentView = background

        super.init(window: window)

        window.onCancel = { [weak self] in self?.onCancel?() }
        state.onPresentationChange = { [weak self] in self?.applyPresentation(animated: true) }

        let center = NotificationCenter.default
        observers.append(
            center.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main)
            { [weak self] _ in
                MainActor.assumeIsolated { self?.updateFrame() }
            })
        observers.append(
            center.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) {
                [weak self] _ in
                MainActor.assumeIsolated { self?.updateFrame() }
            })
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func showWindow(_ sender: Any?) {
        updateFrame()
        applyPresentation(animated: false)
        window?.orderFront(sender)
    }

    // MARK: Frame

    /// The screen chosen in Settings, or the main screen when it is not connected.
    static func targetScreen() -> NSScreen? {
        let id = UserDefaults.standard.string(forKey: DefaultsKey.screenID)
        return NSScreen.screens.first { $0.blotterID == id } ?? NSScreen.screens.first
    }

    static func frame(on screen: NSScreen) -> CGRect {
        let defaults = UserDefaults.standard
        let frame = WindowGeometry.frame(
            in: screen.visibleFrame,
            size: CalendarSize(rawValue: defaults.integer(forKey: DefaultsKey.calendarSize)) ?? .normal,
            position: CalendarPosition(rawValue: defaults.integer(forKey: DefaultsKey.calendarPosition)) ?? .topLeft,
            customFactors: AppDefaults.customFrame
        )
        return screen.backingAlignedRect(frame, options: [.alignAllEdgesNearest])
    }

    private func updateFrame() {
        guard let window, let screen = Self.targetScreen() else { return }
        let frame = Self.frame(on: screen)
        guard frame != lastFrame else { return }
        lastFrame = frame
        window.setFrame(frame, display: true)
    }

    // MARK: Presentation

    private func applyPresentation(animated: Bool) {
        guard let window = window as? DesktopWindow else { return }
        let toFront = state.presentation == .front
        let targetAlpha: CGFloat = state.isFaded ? Self.fadedAlpha : 1
        let changesLevel = window.isInFront != toFront
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let duration = animated && !reduceMotion ? Self.fadeDuration : 0

        guard changesLevel else {
            animateAlpha(of: window, to: targetAlpha, duration: duration)
            return
        }

        animateAlpha(of: window, to: 0, duration: duration / 2) { [weak self] in
            guard let self else { return }
            window.isInFront = toFront
            window.level = toFront ? .floating : Self.desktopLevel
            window.collectionBehavior = toFront ? Self.frontBehavior : Self.desktopBehavior
            window.ignoresMouseEvents = !toFront
            if toFront {
                window.makeKeyAndOrderFront(nil)
            } else {
                window.orderFront(nil)
            }
            self.animateAlpha(of: window, to: targetAlpha, duration: duration / 2)
        }
    }

    private func animateAlpha(
        of window: NSWindow, to alpha: CGFloat, duration: TimeInterval, completion: (@MainActor () -> Void)? = nil
    ) {
        guard duration > 0 else {
            window.alphaValue = alpha
            completion?()
            return
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .linear)
            window.animator().alphaValue = alpha
        } completionHandler: {
            MainActor.assumeIsolated { completion?() }
        }
    }

    private static func roundedMask(radius: CGFloat) -> NSImage {
        let size = NSSize(width: radius * 2 + 1, height: radius * 2 + 1)
        let image = NSImage(size: size, flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        image.resizingMode = .stretch
        return image
    }
}

/// Borderless windows cannot become key by default; the calendar can while it is in front, so Escape works.
final class DesktopWindow: NSWindow {
    var isInFront = false
    var onCancel: (() -> Void)?

    override var canBecomeKey: Bool { isInFront }

    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }
}

extension NSScreen {
    /// A stable identifier for the display, matching the one Blotter 2.x stored.
    var blotterID: String? {
        guard let number = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber,
            let uuid = CGDisplayCreateUUIDFromDisplayID(number.uint32Value)?.takeRetainedValue()
        else { return nil }
        return CFUUIDCreateString(nil, uuid) as String
    }
}
