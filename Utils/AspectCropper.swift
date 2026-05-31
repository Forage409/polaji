import UIKit

enum AspectCropper {
    /// 把任意尺寸的图片中心裁剪成 width:height 的指定比例。
    /// 横图、宽于目标比例的会从中心裁两侧；竖图过窄的会裁上下。
    static func centerCrop(_ image: UIImage, aspect: CGFloat) -> UIImage {
        let cg = image.cgImage
        let size = image.size
        guard size.width > 0, size.height > 0 else { return image }

        let imageAspect = size.width / size.height
        var cropRect = CGRect(origin: .zero, size: size)

        if imageAspect > aspect {
            // Source is wider than target - trim left/right
            let newWidth = size.height * aspect
            cropRect = CGRect(
                x: (size.width - newWidth) / 2,
                y: 0,
                width: newWidth,
                height: size.height
            )
        } else if imageAspect < aspect {
            // Source is taller than target - trim top/bottom
            let newHeight = size.width / aspect
            cropRect = CGRect(
                x: 0,
                y: (size.height - newHeight) / 2,
                width: size.width,
                height: newHeight
            )
        }

        // Honor image orientation by going through UIGraphicsImageRenderer.
        // CGImage cropping ignores .imageOrientation and could rotate the result.
        let renderer = UIGraphicsImageRenderer(size: cropRect.size)
        let cropped = renderer.image { _ in
            image.draw(at: CGPoint(x: -cropRect.minX, y: -cropRect.minY))
        }
        _ = cg // keep reference, prevents over-eager release
        return cropped
    }
}
