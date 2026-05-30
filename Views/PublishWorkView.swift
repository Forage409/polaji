import SwiftUI

struct PublishWorkView: View {
    let template: Template
    let card: GeneratedCard
    let image: UIImage
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title: String
    @State private var description: String = ""
    @State private var isAnonymous = false
    @State private var isPublishing = false
    @State private var showAlert = false
    @State private var alertMsg = ""
    
    init(template: Template, card: GeneratedCard, image: UIImage) {
        self.template = template
        self.card = card
        self.image = image
        _title = State(initialValue: card.title)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 250)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("作品标题")
                            .font(.system(size: 14, weight: .bold))
                        TextField("给你的神作起个响亮的名字", text: $title)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("作品描述 (可选)")
                            .font(.system(size: 14, weight: .bold))
                        TextEditor(text: $description)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    
                    Toggle("匿名发布", isOn: $isAnonymous)
                        .font(.system(size: 14, weight: .bold))
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .padding()
            }
            .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
            .navigationTitle("发布到广场")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.themeTextSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: publish) {
                        if isPublishing {
                            ProgressView()
                        } else {
                            Text("发布")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.themePrimary)
                        }
                    }
                    .disabled(isPublishing || title.isEmpty)
                }
            }
            .toast(isPresented: $showAlert, message: alertMsg)
        }
    }
    
    private func publish() {
        isPublishing = true

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            alertMsg = "图片处理失败"
            showAlert = true
            isPublishing = false
            return
        }

        Task {
            do {
                let success = try await PublicWorksService.shared.publishWork(
                    title: title,
                    description: description,
                    isAnonymous: isAnonymous,
                    tags: template.tags,
                    templateId: template.id,
                    category: template.category,
                    imageData: imageData
                )

                await MainActor.run {
                    isPublishing = false
                    if success {
                        alertMsg = "发布成功！"
                        showAlert = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    } else {
                        alertMsg = "发布失败，请重试"
                        showAlert = true
                    }
                }
            } catch let error as APIError {
                await MainActor.run {
                    isPublishing = false
                    alertMsg = "发布失败：\(error.errorDescription ?? "未知错误")"
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isPublishing = false
                    alertMsg = "发布失败：\(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}
