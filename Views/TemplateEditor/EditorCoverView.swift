import SwiftUI
import PhotosUI

struct EditorCoverView: View {
    @ObservedObject var draft: TemplateDraft
    @State private var selectedItem: PhotosPickerItem? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("上传一张高质量的封面图片，能够吸引更多人使用你的玩法。\n建议比例 3:4。")
                    .font(.system(size: 14))
                    .foregroundColor(.themeTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                    if let image = draft.coverImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 240, height: 320)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 240, height: 320)
                            
                            VStack {
                                Image(systemName: "plus.photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("选择图片")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .padding(.top, 8)
                            }
                        }
                    }
                }
                .onChange(of: selectedItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            DispatchQueue.main.async {
                                // Simplified crop concept for now:
                                // In a real app, this would push a TOCropViewController or custom cropper
                                self.draft.coverImage = uiImage
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}
