import SwiftUI

class ImageExportManager {
    static let shared = ImageExportManager()
    
    @MainActor
    func renderImage<V: View>(from view: V, width: CGFloat) -> UIImage? {
        let exportView = ZStack {
            Color.white
            view
        }
        .frame(width: width)
        
        let renderer = ImageRenderer(content: exportView)
        renderer.scale = UIScreen.main.scale
        renderer.isOpaque = true
        return renderer.uiImage
    }
    
    @MainActor
    func renderPNG<V: View>(from view: V, width: CGFloat) -> Data? {
        let exportView = view
            .frame(width: width)
        let renderer = ImageRenderer(content: exportView)
        renderer.scale = UIScreen.main.scale
        renderer.isOpaque = false
        return renderer.uiImage?.pngData()
    }
    
    func saveImageToPhotos(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        let saver = ImageSaver(completion: completion)
        saver.writeToPhotoAlbum(image: image)
    }
    
    func saveImageToDocuments(_ image: UIImage, fileName: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentDirectory = paths.first else { return nil }
        
        let fileURL = documentDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL)
            return fileName // Return relative path instead of absolute path
        } catch {
            print("Error saving image to documents: \(error)")
            return nil
        }
    }
    
    func loadImage(from path: String) -> UIImage? {
        // Support legacy absolute paths (though they break on restart)
        if path.starts(with: "file://"), let url = URL(string: path) {
            return UIImage(contentsOfFile: url.path)
        } else if path.starts(with: "/") {
            return UIImage(contentsOfFile: path)
        }
        
        // Check Document Directory (new format: relative paths)
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if let documentDirectory = urls.first {
            let fileURL = documentDirectory.appendingPathComponent(path)
            if let image = UIImage(contentsOfFile: fileURL.path) {
                return image
            }
        }
        
        // Fallback to asset catalog
        return UIImage(named: path.replacingOccurrences(of: ".png", with: ""))
    }
    
    func shareImage(_ image: UIImage, from sourceView: UIView? = nil) {
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            
            if let popoverController = activityVC.popoverPresentationController {
                if let sourceView = sourceView {
                    popoverController.sourceView = sourceView
                    popoverController.sourceRect = sourceView.bounds
                } else {
                    popoverController.sourceView = rootVC.view
                    popoverController.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                    popoverController.permittedArrowDirections = []
                }
            }
            
            rootVC.present(activityVC, animated: true)
        }
    }
}

class ImageSaver: NSObject {
    var completion: ((Bool) -> Void)?
    private static var activeSavers: [ImageSaver] = []
    
    init(completion: @escaping (Bool) -> Void) {
        self.completion = completion
        super.init()
        ImageSaver.activeSavers.append(self)
    }
    
    func writeToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
    }
    
    @objc func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let _ = error {
            completion?(false)
        } else {
            completion?(true)
        }
        if let index = ImageSaver.activeSavers.firstIndex(of: self) {
            ImageSaver.activeSavers.remove(at: index)
        }
    }
}
