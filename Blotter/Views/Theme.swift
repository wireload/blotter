import BlotterKit
import SwiftUI

/// Colours of the calendar, for light and dark appearances.
///
/// The calendar sits on the desktop wallpaper, so text gets a soft shadow (dark appearance) or glow (light
/// appearance) to stay legible on busy wallpapers.
struct Theme {
    let colorScheme: ColorScheme

    private var isDark: Bool { colorScheme == .dark }

    var text: Color { isDark ? .white : Color(white: 0.08) }
    var secondaryText: Color { text.opacity(isDark ? 0.75 : 0.65) }
    var textShadow: Color { isDark ? .black.opacity(0.35) : .white.opacity(0.7) }

    /// Tint behind the whole calendar while it sits on the desktop.
    var desktopBackground: Color { isDark ? .black.opacity(0.38) : .white.opacity(0.5) }
    /// Tint over the blurred background while the calendar is in front.
    var frontBackground: Color { isDark ? .black.opacity(0.12) : .white.opacity(0.12) }
    var outline: Color { isDark ? .white.opacity(0.14) : .black.opacity(0.12) }

    var panelFill: Color { isDark ? .white.opacity(0.06) : .black.opacity(0.035) }
    var columnFill: LinearGradient {
        LinearGradient(
            colors: isDark
                ? [.white.opacity(0.10), .white.opacity(0.03)] : [.black.opacity(0.05), .black.opacity(0.02)],
            startPoint: .top, endPoint: .bottom)
    }

    func eventFill(_ color: RGBAColor) -> Color { Color(color).opacity(isDark ? 0.5 : 0.26) }
    var eventText: Color { isDark ? .white : Color(white: 0.1) }
    var eventSecondaryText: Color { eventText.opacity(0.75) }
    var eventStroke: Color { isDark ? .white.opacity(0.22) : .black.opacity(0.08) }

    var nowLine: Color { isDark ? .white.opacity(0.8) : .black.opacity(0.6) }
}

extension View {
    /// Shadow (dark appearance) or glow (light appearance) for text drawn over the desktop.
    func desktopTextShadow() -> some View {
        modifier(DesktopTextShadow())
    }
}

private struct DesktopTextShadow: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.shadow(
            color: Theme(colorScheme: colorScheme).textShadow, radius: 1, x: 0, y: colorScheme == .dark ? 1 : 0)
    }
}

extension Color {
    init(_ color: RGBAColor) {
        self.init(.sRGB, red: color.red, green: color.green, blue: color.blue, opacity: color.alpha)
    }
}

/// Animations used across the calendar, all honouring Reduce Motion.
enum Motion {
    static func navigation(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeInOut(duration: 0.15) : .smooth(duration: 0.35)
    }

    static func update(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .smooth(duration: 0.3)
    }
}
