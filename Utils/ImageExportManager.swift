import SwiftUI

class ImageExportManager {
    static let shared = ImageExportManager()
    
    @MainActor
    func renderImage<V: View>(from view: V, size: CGSize) -> UIImage? {
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
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
            return fileURL.path
        } catch {
            print("Error saving image to documents: \(error)")
            return nil
        }
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
    
    init(completion: @escaping (Bool) -> Void) {
        self.completion = completion
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
    }
}
