
+13
−6
import SwiftUI
 
class ImageExportManager {
    static let shared = ImageExportManager()
    
    @MainActor
    func renderImage<V: View>(from view: V, size: CGSize) -> UIImage? {
        let exportView = ZStack {
            Color.white
            view
        }
        .frame(width: size.width, height: size.height)
        
        let exportView = view
            .frame(width: size.width, height: size.height)
        let renderer = ImageRenderer(content: exportView)
        renderer.scale = UIScreen.main.scale
        renderer.isOpaque = true
        return renderer.uiImage
    }
    
    @MainActor
    func renderPNG<V: View>(from view: V, size: CGSize) -> Data? {
        let exportView = view
            .frame(width: size.width, height: size.height)
        let renderer = ImageRenderer(content: exportView)
        renderer.scale = UIScreen.main.scale
        renderer.isOpaque = false
        return renderer.uiImage?.pngData()
    }
    
    func saveImageToPhotos(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        let saver = ImageSaver(completion: completion)
        saver.writeToPhotoAlbum(image: image)

CustomTabView.swift
