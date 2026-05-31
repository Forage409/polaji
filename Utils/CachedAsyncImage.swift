import SwiftUI

/// AsyncImage with persistent URLCache so the same URL doesn't refetch on every appearance.
/// SwiftUI's built-in AsyncImage does not cache across view recreations.
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var image: UIImage? = nil
    @State private var isLoading = false

    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .onAppear { load() }
            }
        }
        .id(url?.absoluteString ?? "")
    }

    private func load() {
        guard !isLoading, image == nil, let url = url else { return }
        isLoading = true

        if let cached = ImageCache.shared.image(for: url) {
            self.image = cached
            self.isLoading = false
            return
        }

        Task.detached {
            do {
                let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
                let (data, _) = try await URLSession.shared.data(for: request)
                guard let img = UIImage(data: data) else {
                    await MainActor.run { self.isLoading = false }
                    return
                }
                ImageCache.shared.set(img, for: url)
                await MainActor.run {
                    self.image = img
                    self.isLoading = false
                }
            } catch {
                await MainActor.run { self.isLoading = false }
            }
        }
    }
}

final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 80 * 1024 * 1024 // 80 MB
        // Configure URLCache for HTTP-level caching
        let mb = 1024 * 1024
        URLCache.shared = URLCache(memoryCapacity: 20 * mb, diskCapacity: 200 * mb, diskPath: "ImageURLCache")
    }

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url.absoluteString as NSString)
    }

    func set(_ image: UIImage, for url: URL) {
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: url.absoluteString as NSString, cost: cost)
    }
}
