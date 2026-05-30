import SwiftUI

struct EditorPreviewPublishView: View {
    @ObservedObject var draft: TemplateDraft
    @Environment(\.presentationMode) var presentationMode
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
        if draft.formFields.isEmpty {
            alertMsg = "请至少添加一个表单字段"
            showAlert = true
            return
        }
        if draft.resultRule.titleTemplate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            alertMsg = "请填写生成结果的标题模板"
            showAlert = true
            return
        }
        
        isPublishing = true
        
        RemoteTemplateService.shared.createTemplate(draft: RemoteTemplate(id: UUID().uuidString, title: draft.title, description: draft.description, coverImage: "tpl_user_1", category: draft.category, authorId: "test_user", authorName: "测试用户", viewCount: 0, startCount: 0, generateCount: 0, usageCount: 0, shareCount: 0, likeCount: 0, reportCount: 0, status: "published", createdAt: "", updatedAt: "", formConfigRaw: nil, resultConfigRaw: nil)) { success in
            isPublishing = false
            if success {
                alertMsg = "发布成功！"
                showAlert = true
                // Fallback local insert for real-time feel
                let newMock = Template(id: UUID().uuidString, name: draft.title, category: draft.category, description: draft.description, coverImage: "tpl_user_1", isVip: false, usageCount: 0, tags: draft.tags, fields: [])
                MockData.allTemplates.insert(newMock, at: 0)
                // Refresh feed locally
                NotificationCenter.default.post(name: NSNotification.Name("RefreshFeed"), object: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    presentationMode.wrappedValue.dismiss()
                }
            } else {
                alertMsg = "发布失败，请检查网络"
                showAlert = true
            }
        }
    }
}
