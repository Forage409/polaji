import SwiftUI
import PhotosUI
 
struct EditProfileView: View {
    @ObservedObject private var profile = UserProfileStore.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var draftNickname: String = ""
    @State private var draftBio: String = ""
    @State private var draftAvatar: String = "logo"
    @State private var showCopied = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var isSaving = false
    @State private var showSaveAlert = false
    @State private var saveAlertMessage = ""
    
    private let avatarOptions: [String] = [
        "logo",
        "theme_dreamy_persona_hero_1",
        "theme_pop_party_hero_1",
        "theme_pink_crush_hero_1",
        "theme_midnight_mode_hero_1",
        "theme_office_satire_hero_1",
        "theme_courtroom_red_hero_1",
        "theme_fortune_gold_hero_1",
        "theme_campus_fun_hero_1",
        "theme_weekend_chill_hero_1"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                avatarSection
                
                fieldSection(title: "昵称") {
                    TextField("给自己起个昵称", text: $draftNickname)
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(12)
                }
                
                fieldSection(title: "个人简介") {
                    ZStack(alignment: .topLeading) {
                        if draftBio.isEmpty {
                            Text("一句话介绍你的整活风格")
                                .font(.system(size: 14))
                                .foregroundColor(.themeTextSecondary.opacity(0.5))
                                .padding(.horizontal, 16)
                                .padding(.top, 14)
                        }
                        TextEditor(text: $draftBio)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .frame(minHeight: 100)
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                }
                
                userIdRow
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle("编辑资料")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isSaving ? "保存中..." : "保存", action: save)
                    .fontWeight(.bold)
                    .disabled(isSaving || draftNickname.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundColor(draftNickname.trimmingCharacters(in: .whitespaces).isEmpty ? .themeTextSecondary : Color(hex: "B58900"))
            }
        }
        .onAppear {
            draftNickname = profile.nickname
            draftBio = profile.bio
            draftAvatar = profile.avatarName
        }
        .toast(isPresented: $showCopied, message: "ID 已复制")
        .toast(isPresented: $showSaveAlert, message: saveAlertMessage)
    }
    
    private var avatarSection: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                AvatarImage(name: draftAvatar)
                    .scaledToFill()
                    .frame(width: 96, height: 96)
                    .clipShape(Circle())
                
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Image(systemName: "camera.circle.fill")
                        .resizable()
                        .frame(width: 28, height: 28)
                        .foregroundColor(.themePrimary)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                .onChange(of: selectedItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            let fileName = "custom_\(UUID().uuidString).jpg"
                            if let _ = ImageExportManager.shared.saveImageToDocuments(image, fileName: fileName) {
                                await MainActor.run {
                                    draftAvatar = fileName
                                }
                            }
                        }
                    }
                }
            }
            
            Text("选择头像或从相册上传")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.themeTextSecondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(avatarOptions, id: \.self) { name in
                        Button(action: { draftAvatar = name }) {
                            AvatarImage(name: name)
                                .scaledToFill()
                                .frame(width: 52, height: 52)
                                .clipShape(Circle())
                                .padding(3)
                                .overlay(
                                    Circle()
                                        .stroke(name == draftAvatar ? Color.themePrimary : Color.clear, lineWidth: 3)
                                )
                        }
                        .padding(.vertical, 4) // Prevent vertical clipping
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private func fieldSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.themeTextSecondary)
                .padding(.horizontal, 4)
            content()
        }
    }
    
    private var userIdRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("我的 ID")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.themeTextMain)
                Text(profile.userId)
                    .font(.system(size: 13))
                    .foregroundColor(.themeTextSecondary)
            }
            Spacer()
            Button(action: copyId) {
                Text("复制")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.themeTextMain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.themePrimary.opacity(0.22))
                    .cornerRadius(12)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private func copyId() {
        UIPasteboard.general.string = profile.userId
        showCopied = true
    }
    
    private func save() {
        let trimmed = draftNickname.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isSaving = true
        Task {
            do {
                let finalAvatar = try await uploadAvatarIfNeeded(draftAvatar)
                await MainActor.run {
                    profile.nickname = trimmed
                    profile.bio = draftBio.trimmingCharacters(in: .whitespacesAndNewlines)
                    profile.avatarName = finalAvatar
                    isSaving = false
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    saveAlertMessage = "头像上传失败，请检查网络后重试"
                    showSaveAlert = true
                }
            }
        }
    }

    private func uploadAvatarIfNeeded(_ avatar: String) async throws -> String {
        guard avatar.hasPrefix("custom_"),
              let image = ImageExportManager.shared.loadImage(from: avatar),
              let data = image.jpegData(compressionQuality: 0.82) else {
            return avatar
        }
        return try await APIClient.shared.upload(path: "/api/upload", data: data, contentType: "image/jpeg")
    }
}
