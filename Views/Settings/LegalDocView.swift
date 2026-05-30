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
                ("一、我们收集哪些信息", """
                整活局 App 在本版本中是一款纯本地运行的工具，我们不会主动收集你的任何个人信息，也不会将数据上传到任何服务器。

                你在 App 内输入的昵称、性别、关键词、判官参与人姓名等内容，仅会用于在你本人的设备上生成卡片，并保存在你的设备本地（UserDefaults 与 Documents 目录），不会以任何形式离开你的手机。
                """),
                ("二、相册与照片权限", """
                当你点击"保存图片"时，整活局会请求"添加到相册"权限，仅用于把你生成的整活卡片写入系统相册。我们不会读取你相册里的其它照片，也不会上传任何图片。

                你可以随时在系统「设置 > 隐私与安全性 > 照片」中关闭该权限。
                """),
                ("三、通知权限", """
                你可以选择开启或关闭本地通知。我们不会推送任何营销内容，本地通知仅用于你自己设置的每日生成提醒（如有）。
                """),
                ("四、儿童隐私", """
                整活局不向 14 岁以下儿童定向收集任何信息。如发现误收集，请通过"意见反馈"联系我们删除。
                """),
                ("五、隐私政策变更", """
                如果隐私政策有任何变更，我们会在 App 更新时在本页面更新，并在重要变更时通过显眼方式提示你。
                """),
                ("六、联系我们", """
                如对隐私政策有任何疑问，可通过"意见反馈"功能联系整活局团队。
                """)
            ]
        case .terms:
            return [
                ("一、服务说明", """
                整活局是一款由整活局团队开发的中文整活卡片生成工具。所有模板、文案库均为虚构创作，内容仅供朋友间娱乐使用，请勿当真。
                """),
                ("二、用户行为规范", """
                你不得使用本 App 生成的内容进行：
                • 人身攻击、辱骂或网络暴力
                • 涉及色情、暴力、赌博、政治敏感等违法违规内容的传播
                • 冒充他人或冒用真实身份生成判决书 / 投票榜
                • 任何违反所在国家 / 地区法律法规的行为
                """),
                ("三、内容免责", """
                所有由模板生成的"鉴定结果"、"投票排名"、"判决书"均为随机文案组合，不构成任何形式的真实评价、命理预测或法律意见，请勿作为现实判断依据。
                """),
                ("四、知识产权", """
                整活局 App 的图标、UI、模板文案、卡片样式版权均归整活局团队所有。生成的卡片仅供个人非商业用途使用，未经授权不得用于商业宣传。
                """),
                ("五、付费与会员", """
                正式版上线后，会员订阅 / 内购通过 Apple App Store 支付通道完成，订阅会自动续费除非你在 App Store 主动取消。当前体验版的购买按钮为占位，未发生实际扣费。
                """),
                ("六、协议变更", """
                我们可能不时更新本协议，更新后将在 App 内同步展示。继续使用本 App 即视为你接受最新版本协议。
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
                Text("生效日期：2026 年 5 月 30 日")
                    .font(.system(size: 12))
                    .foregroundColor(.themeTextSecondary)

                ForEach(0..<kind.sections.count, id: \.self) { idx in
                    let section = kind.sections[idx]
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
