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
                
                // Simplified preview card
                VStack(spacing: 12) {
                    if let image = draft.coverImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 180)
                    }
                    
                    Text(draft.title.isEmpty ? "玩法标题" : draft.title)
                        .font(.system(size: 18, weight: .bold))
                    
                    Text(draft.description.isEmpty ? "玩法描述..." : draft.description)
                        .font(.system(size: 14))
                        .foregroundColor(.themeTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                }
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                .padding(.horizontal, 30)
                
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
        guard !draft.title.isEmpty else {
            alertMsg = "请填写标题"
            showAlert = true
            return
        }
        
        isPublishing = true
        
        // Mock publish flow: upload cover -> create remote template -> finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isPublishing = false
            alertMsg = "发布成功！"
            showAlert = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
