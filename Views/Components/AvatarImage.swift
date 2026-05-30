import SwiftUI

struct AvatarImage: View {
    let name: String
    
    var body: some View {
        if name.hasPrefix("custom_") {
            if let image = ImageExportManager.shared.loadImage(from: name) {
                Image(uiImage: image)
                    .resizable()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundColor(Color.gray.opacity(0.5))
            }
        } else if name.isEmpty {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .foregroundColor(Color.gray.opacity(0.5))
        } else {
            Image.bundle(name)
                .resizable()
        }
    }
}
