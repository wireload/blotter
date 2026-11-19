import AppKit
import BlotterKit
import SwiftUI

/// Colours of the calendar, for light and dark appearances, following Apple's Calendar app and desktop widgets:
/// neutral cards, red for today and the current time, and events tinted in their calendar's colour.
struct Theme {
    let colorScheme: ColorScheme

    private var isDark: Bool { colorScheme == .dark }

    var text: Color { isDark ? .white : .black.opacity(0.85) }
    var secondaryText: Color { isDark ? .white.opacity(0.55) : .black.opacity(0.5) }

    /// Calendar's red: today, the current time and section titles.
    var accent: Color { Color(nsColor: .systemRed) }

    /// Background of a widget-style card on the desktop.
    var card: Color { isDark ? .black.opacity(0.34) : .white.opacity(0.68) }
    var cardStroke: Color { isDark ? .white.opacity(0.1) : .black.opacity(0.06) }
    var cardShadow: Color { .black.opacity(isDark ? 0.25 : 0.12) }
    /// Tint over the blurred background while the calendar is in front.
    var frontBackground: Color { isDark ? .black.opacity(0.15) : .white.opacity(0.2) }

    var gridLine: Color { isDark ? .white.opacity(0.1) : .black.opacity(0.08) }
    var weekendFill: Color { isDark ? .white.opacity(0.035) : .black.opacity(0.025) }

    /// An opaque tint of the calendar colour. Opaque, so overlapping events do not show through each other.
    func eventFill(_ color: RGBAColor) -> Color {
        var fill = isDark ? color.mixed(with: .black, by: 0.62) : color.mixed(with: .white, by: 0.8)
        fill.alpha = 1
        return Color(fill)
    }
    /// The hairline around events, matching the card behind them.
    var eventEdge: Color { isDark ? .black.opacity(0.35) : .white.opacity(0.8) }
    /// Event text in a darker (light appearance) or lighter (dark appearance) shade of the calendar colour.
    func eventText(_ color: RGBAColor) -> Color {
        Color(isDark ? color.mixed(with: .white, by: 0.45) : color.mixed(with: .black, by: 0.45))
    }
}

extension Color {
    init(_ color: RGBAColor) {
        self.init(.sRGB, red: color.red, green: color.green, blue: color.blue, opacity: color.alpha)
    }
}

/// A widget-style card: rounded, softly shadowed, with an optional title in the accent colour.
struct Card<Content: View>: View {
    var title: LocalizedStringKey?
    @ViewBuilder let content: Content

    @Environment(\.colorScheme) private var colorScheme

    static var cornerRadius: CGFloat { 20 }
    static var padding: CGFloat { 14 }

    var body: some View {
        let theme = Theme(colorScheme: colorScheme)
        let shape = RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.accent)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)
            }
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(Self.padding)
        .background {
            shape
                .fill(theme.card)
                .shadow(color: theme.cardShadow, radius: 10, x: 0, y: 3)
        }
        .overlay(shape.strokeBorder(theme.cardStroke, lineWidth: 0.5))
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
