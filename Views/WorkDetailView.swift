import SwiftUI

struct WorkDetailView: View {
    let work: Work
    @StateObject private var store = WorksStore()
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack {
            Spacer()
            
            if let uiImage = loadImage() {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(24)
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                    .padding(20)
            } else {
                Text("图片已丢失")
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {
                    if let image = loadImage() {
                        ImageExportManager.shared.saveImageToPhotos(image) { success in
                            alertMessage = success ? "已保存到系统相册！" : "保存失败，请检查相册权限。"
                            showingAlert = true
                        }
                    }
                }) {
                    Text("保存图片")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.themeTextMain)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.themePrimary)
                        .cornerRadius(25)
                }
                
                Button(action: {
                    if let image = loadImage() {
                        ImageExportManager.shared.shareImage(image)
                    }
                }) {
                    Text("分享给好友")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.themeTextMain)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.themePrimary)
                        .cornerRadius(25)
                }
            }
            .padding(.horizontal, 20)
            
            Button(action: {
                store.deleteWork(id: work.id)
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("删除记录")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .padding(.top, 12)
            }
            .padding(.bottom, 20)
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle(work.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("提示"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
        }
    }
    
    private func loadImage() -> UIImage? {
        if work.imagePath.starts(with: "/") || work.imagePath.starts(with: "file://") {
            return UIImage(contentsOfFile: work.imagePath)
        } else {
            return UIImage(named: work.imagePath.replacingOccurrences(of: ".png", with: ""))
        }
    }
}
