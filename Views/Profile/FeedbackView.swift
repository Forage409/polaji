import SwiftUI
 
struct FeedbackView: View {
    private let feedbackEmail = "foragekc@outlook.com"
    
    @State private var content: String = ""
    @State private var contact: String = ""
    @State private var category: String = "我有一个想法"
    @State private var showMailNotAvailable = false
    @State private var showCopiedToast = false
    
    private let categories: [String] = ["我有一个想法", "Bug 反馈", "模板建议", "审核 / 内容问题", "其他"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                categoryCard
                contentCard
                contactCard
                submitButton
                directContactCard
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle("意见反馈")
        .navigationBarTitleDisplayMode(.inline)
        .alert("无法打开邮件", isPresented: $showMailNotAvailable) {
            Button("复制邮箱") {
                UIPasteboard.general.string = feedbackEmail
                showCopiedToast = true
            }
            Button("好的", role: .cancel) {}
        } message: {
            Text("没有检测到可用邮箱客户端，请手动联系：\(feedbackEmail)")
        }
        .alert("邮箱已复制", isPresented: $showCopiedToast) {
            Button("好的", role: .cancel) {}
        } message: {
            Text("快去你的邮件 App 给我们发反馈吧！")
        }
    }
    
    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("反馈类型")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.themeTextSecondary)
                .padding(.horizontal, 4)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { c in
                        Text(c)
                            .font(.system(size: 13))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(category == c ? Color.themePrimary : Color.white)
                            .foregroundColor(category == c ? .themeTextMain : .themeTextSecondary)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(category == c ? Color.themePrimary : Color.gray.opacity(0.15), lineWidth: 1)
                            )
                            .onTapGesture { category = c }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("反馈内容")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.themeTextSecondary)
                .padding(.horizontal, 4)
            ZStack(alignment: .topLeading) {
                if content.isEmpty {
                    Text("说说你遇到的问题或想看到的玩法吧～")
                        .font(.system(size: 14))
                        .foregroundColor(.themeTextSecondary.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                }
                TextEditor(text: $content)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(minHeight: 140)
            }
            .background(Color.white)
            .cornerRadius(14)
            HStack {
                Spacer()
                Text("\(content.count)/500")
                    .font(.system(size: 11))
                    .foregroundColor(.themeTextSecondary)
            }
        }
    }
    
    private var contactCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("联系方式（选填）")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.themeTextSecondary)
                .padding(.horizontal, 4)
            TextField("邮箱 / 微信号 / QQ 号，方便我们回复你", text: $contact)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(Color.white)
                .cornerRadius(14)
        }
    }
    
    private var submitButton: some View {
        Button(action: sendByEmail) {
            Text("通过邮件发送反馈")
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(.themeTextMain)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(content.isEmpty ? Color.themePrimary.opacity(0.4) : Color.themePrimary)
                .cornerRadius(26)
        }
        .disabled(content.isEmpty)
        .padding(.top, 4)
    }
    
    private var directContactCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("或直接发邮件")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.themeTextSecondary)
                .padding(.horizontal, 4)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("整活局开发者邮箱")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.themeTextMain)
                    Text(feedbackEmail)
                        .font(.system(size: 13))
                        .foregroundColor(.themeTextSecondary)
                }
                Spacer()
                Button(action: copyEmail) {
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
            .cornerRadius(14)
        }
    }
    
    private func copyEmail() {
        UIPasteboard.general.string = feedbackEmail
        showCopiedToast = true
    }
    
    private func sendByEmail() {
        let subject = "[整活局反馈] \(category)"
        var bodyText = content
        if !contact.isEmpty {
            bodyText += "\n\n———\n联系方式: \(contact)"
        }
        bodyText += "\n\n———\n反馈类型: \(category)"
        bodyText += "\nApp 版本: V \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0")"
        bodyText += "\n设备: \(UIDevice.current.model) / iOS \(UIDevice.current.systemVersion)"
        
        let allowed = CharacterSet.urlQueryAllowed
        let s = subject.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        let b = bodyText.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        let urlStr = "mailto:\(feedbackEmail)?subject=\(s)&body=\(b)"
        
        guard let url = URL(string: urlStr) else {
            showMailNotAvailable = true
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            showMailNotAvailable = true
        }
    }
}
