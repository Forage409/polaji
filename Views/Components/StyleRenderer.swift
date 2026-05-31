import SwiftUI

/// 把 TemplateCardStyle 转换成实际的 SwiftUI 渐变、颜色等。
/// 让 EditorImageStyleView 和 CustomResultCardUI 共享同一套渲染逻辑。
enum StyleRenderer {
    static func gradient(for bg: TemplateCardStyle.Background) -> LinearGradient {
        let colors: [Color]
        switch bg {
        case .purpleHaze:
            colors = [Color(red: 0.85, green: 0.80, blue: 0.97), Color(red: 0.95, green: 0.90, blue: 1.00)]
        case .creamYellow:
            colors = [Color(red: 1.00, green: 0.93, blue: 0.74), Color(red: 1.00, green: 0.97, blue: 0.86)]
        case .mintGreen:
            colors = [Color(red: 0.78, green: 0.95, blue: 0.85), Color(red: 0.91, green: 0.99, blue: 0.94)]
        case .sakuraPink:
            colors = [Color(red: 1.00, green: 0.83, blue: 0.88), Color(red: 1.00, green: 0.93, blue: 0.95)]
        case .midnightBlue:
            colors = [Color(red: 0.18, green: 0.20, blue: 0.40), Color(red: 0.32, green: 0.36, blue: 0.60)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func textColor(for bg: TemplateCardStyle.Background) -> Color {
        switch bg {
        case .midnightBlue: return Color.white
        default: return Color(red: 0.16, green: 0.17, blue: 0.21)
        }
    }

    static func subTextColor(for bg: TemplateCardStyle.Background) -> Color {
        switch bg {
        case .midnightBlue: return Color.white.opacity(0.7)
        default: return Color(red: 0.45, green: 0.45, blue: 0.55)
        }
    }

    static func accentColor(for bg: TemplateCardStyle.Background) -> Color {
        switch bg {
        case .purpleHaze: return Color(red: 0.55, green: 0.45, blue: 0.95)
        case .creamYellow: return Color(red: 0.95, green: 0.65, blue: 0.20)
        case .mintGreen: return Color(red: 0.30, green: 0.75, blue: 0.55)
        case .sakuraPink: return Color(red: 0.92, green: 0.42, blue: 0.55)
        case .midnightBlue: return Color(red: 1.00, green: 0.85, blue: 0.45)
        }
    }
}
