import SwiftUI

struct AboutView: View {
    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "整活局"
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image.bundle("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                    Text(appName)
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.themeTextMain)
                    Text("和朋友一起整活，好玩又有梗")
                        .font(.system(size: 14))
                        .foregroundColor(.themeTextSecondary)
                    Text("V \(version) (Build \(build))")
                        .font(.system(size: 12))
                        .foregroundColor(.themeTextSecondary)
                        .padding(.top, 4)
                }
                .padding(.top, 30)

                VStack(alignment: .leading, spacing: 0) {
                    aboutRow(title: "产品介绍") {
                        Text("整活局是一款中文娱乐卡片生成器。生成逻辑在本地运行；当你主动发布玩法或广场作品时，相关公开内容会上传到云端供其他用户浏览。")
                            .font(.system(size: 14))
                            .foregroundColor(.themeTextMain.opacity(0.85))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Divider().padding(.horizontal, 16)
                    NavigationLink(destination: LegalDocView(kind: .privacy)) {
                        rowItem(title: "隐私政策", hint: nil)
                    }
                    Divider().padding(.horizontal, 16)
                    NavigationLink(destination: LegalDocView(kind: .terms)) {
                        rowItem(title: "用户协议", hint: nil)
                    }
                    Divider().padding(.horizontal, 16)
                    rowItem(title: "开发者邮箱", hint: "lapd0897@gmail.com")
                    Divider().padding(.horizontal, 16)
                    rowItem(title: "开发者团队", hint: "整活局")
                }
                .background(Color.white)
                .cornerRadius(14)
                .padding(.horizontal, 16)

                Text("© 2026 整活局 · 所有权利保留")
                    .font(.system(size: 11))
                    .foregroundColor(.themeTextSecondary)
                    .padding(.top, 20)

                Spacer(minLength: 40)
            }
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle("关于整活局")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func aboutRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.themeTextMain)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func rowItem(title: String, hint: String?) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.themeTextMain)
            Spacer()
            if let hint {
                Text(hint)
                    .font(.system(size: 13))
                    .foregroundColor(.themeTextSecondary)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.themeTextSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}
