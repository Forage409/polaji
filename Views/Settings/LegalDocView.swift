import SwiftUI

enum LegalDocKind {
    case privacy
    case terms

    var title: String {
        switch self {
        case .privacy: return "隐私政策"
        case .terms: return "用户协议"
        }
    }

    var sections: [(String, String)] {
        switch self {
        case .privacy:
            return [
                ("一、我们处理的信息", """
                为提供模板、广场和发布功能，整活局会使用匿名设备标识或访问令牌与云端接口通信。昵称、表单输入和生成草稿默认在本地处理；仅当你主动发布玩法或作品时，相关公开内容才会上传。
                """),
                ("二、图片与发布内容", """
                选择保存图片时，App 仅将生成结果写入系统相册。选择发布到广场时，App 会上传最终图片、标题、简介、标签及你选择公开的信息。选择发布玩法时，App 会上传玩法封面、表单配置和结果图配置。
                """),
                ("三、相册权限", """
                App 会在保存结果图或选择自定义头像时请求必要的照片权限。你可以随时在系统设置中关闭权限。
                """),
                ("四、公开内容", """
                你主动发布到广场的作品和玩法会对其他用户可见。请勿发布违法、侵权或包含敏感个人信息的内容。
                """),
                ("五、联系我们", """
                如需反馈隐私问题或申请删除已发布内容，请通过 App 内的意见反馈联系我们。
                """)
            ]
        case .terms:
            return [
                ("一、服务说明", """
                整活局是一款娱乐卡片生成工具。模板、随机文案和结果仅供朋友间娱乐使用，请勿将其作为现实判断依据。
                """),
                ("二、用户行为规范", """
                不得使用本 App 发布人身攻击、网络暴力、违法违规、侵权或冒充他人的内容。请勿上传包含他人敏感个人信息的作品。
                """),
                ("三、内容发布", """
                当你主动发布玩法或作品时，即表示你确认拥有相关内容的使用权，并同意在整活局广场中公开展示。
                """),
                ("四、协议变更", """
                我们可能随 App 更新调整本协议。更新后的内容会在本页面展示。
                """)
            ]
        }
    }
}

struct LegalDocView: View {
    let kind: LegalDocKind

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(kind.title)
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(.themeTextMain)
                Text("生效日期：2026 年 6 月 1 日")
                    .font(.system(size: 12))
                    .foregroundColor(.themeTextSecondary)

                ForEach(0..<kind.sections.count, id: \.self) { index in
                    let section = kind.sections[index]
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.0)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.themeTextMain)
                        Text(section.1)
                            .font(.system(size: 14))
                            .foregroundColor(.themeTextMain.opacity(0.8))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(14)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
