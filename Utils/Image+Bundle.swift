import SwiftUI

extension Image {
    static func bundle(_ name: String) -> Image {
        if let uiImage = UIImage(named: name) {
            return Image(uiImage: uiImage)
        }
        return Image(name)
    }
}
