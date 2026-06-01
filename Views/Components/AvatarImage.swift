import SwiftUI

struct AvatarImage: View {
    let name: String
    
    var body: some View {
        if name.hasPrefix("http://") || name.hasPrefix("https://") {
            CachedAsyncImage(url: RemoteImageURL.resolve(name)) { image in
                image.resizable()
            } placeholder: {
                placeholder
            }
        } else if name.hasPrefix("custom_") {
            if let image = ImageExportManager.shared.loadImage(from: name) {
                Image(uiImage: image)
                    .resizable()
            } else {
                placeholder
            }
        } else if name.isEmpty {
            placeholder
        } else {
            Image.bundle(name)
                .resizable()
        }
    }

    private var placeholder: some View {
        Image.bundle("logo")
            .resizable()
    }
}
