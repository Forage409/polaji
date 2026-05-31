import SwiftUI

struct EditorPreviewPublishView: View {
    @ObservedObject var draft: TemplateDraft
    @Environment(\.dismiss) var dismiss
    @State private var isPublishing = false
    @State private var showAlert = false
    @State private var alertMsg = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("即将发布以下玩法：")
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                // Horizontal WeChat moments style preview
                HStack(spacing: 12) {
                    if let image = draft.coverImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(draft.title.isEmpty ? "玩法标题" : draft.title)
                            .font(.system(size: 16, weight: .bold))
                            .lineLimit(1)
                        
                        Text(draft.description.isEmpty ? "玩法描述..." : draft.description)
                            .font(.system(size: 13))
                            .foregroundColor(.themeTextSecondary)
                            .lineLimit(2)
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 20)
                
                Button(action: {
                    publish()
                }) {
                    Text(isPublishing ? "发布中..." : "确认发布")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.themeTextMain)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.themePrimary)
                        .cornerRadius(25)
                        .padding(.horizontal, 30)
                }
                .disabled(isPublishing)
            }
            .padding(.top, 20)
        }
        .toast(isPresented: $showAlert, message: alertMsg)
    }
    
    private func publish() {
        if draft.coverImage == nil {
            alertMsg = "请上传玩法封面"
            showAlert = true
            return
        }
        if draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            alertMsg = "请填写玩法标题"
            showAlert = true
            return
        }
        if draft.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            alertMsg = "请填写玩法描述"
            showAlert = true
            return
        }
        if draft.fields.isEmpty {
            alertMsg = "请至少添加一个填写项"
            showAlert = true
            return
        }
        if draft.fields.contains(where: { $0.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            alertMsg = "每个填写项都需要起一个名字"
            showAlert = true
            return
        }

        isPublishing = true

        guard let imageData = draft.coverImage?.jpegData(compressionQuality: 0.8) else {
            alertMsg = "封面处理失败"
            showAlert = true
            isPublishing = false
            return
        }

        let capturedTitle = self.draft.title
        let capturedDescription = self.draft.description
        let capturedCategory = self.draft.category
        let formConfigJSON = TemplateFormConfig(fields: self.draft.fields).toJSONString()
        let dismissAction = self.dismiss

        Task {
            do {
                let coverUrl = try await RemoteTemplateService.shared.uploadCover(imageData: imageData)
                let finalCoverUrl = coverUrl

                let draftTemplate = RemoteTemplate(
                    id: UUID().uuidString,
                    title: capturedTitle,
                    description: capturedDescription,
                    coverImage: finalCoverUrl,
                    category: capturedCategory,
                    authorId: UserProfileStore.shared.userId,
                    authorName: UserProfileStore.shared.nickname,
                    viewCount: 0,
                    startCount: 0,
                    generateCount: 0,
                    usageCount: 0,
                    shareCount: 0,
                    likeCount: 0,
                    reportCount: 0,
                    status: "published",
                    createdAt: "",
                    updatedAt: "",
                    formConfigRaw: formConfigJSON,
                    resultConfigRaw: nil
                )

                let success = try await RemoteTemplateService.shared.createTemplate(draft: draftTemplate)

                await MainActor.run {
                    self.isPublishing = false
                    if success {
                        self.alertMsg = "发布成功！"
                        self.showAlert = true
                        NotificationCenter.default.post(name: NSNotification.Name("RefreshFeed"), object: nil)
                        dismissAction()
                    } else {
                        self.alertMsg = "发布失败，请检查网络"
                        self.showAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.isPublishing = false
                    self.alertMsg = "发布失败：\(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }
}
