import UIKit

enum LayoutMetrics {
    static func twoColumnCardWidth(horizontalPadding: CGFloat = 16, spacing: CGFloat = 12) -> CGFloat {
        let available = UIScreen.main.bounds.width - horizontalPadding * 2 - spacing
        return floor(max(0, available / 2))
    }
}
