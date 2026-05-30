import SwiftUI
 
struct DiscoverFeatureCard: Identifiable {
    let id = UUID()
    let templateId: String
    let title: String
    let subtitle: String
    let bgImage: String
    let badge: String
    let gradient: [String]
}
 
struct DiscoverFeedItem: Identifiable {
    let id = UUID()
    let templateId: String
    let title: String
    let summary: String
    let author: String
    let usageCount: Int
    let cover: String
}
 
struct DiscoverView: View {
    private let featureCards: [DiscoverFeatureCard] = [
        DiscoverFeatureCard(
            templateId: "office_survival",
            title: "当代打工人生存图鉴",
            subtitle: "扎心又真实",
            bgImage: "tpl_persona",
            badge: "热门",
            gradient: ["FFE070", "FFB300"]
        ),
        DiscoverFeatureCard(
            templateId: "single_card",
            title: "恋爱脑自测说明书",
            subtitle: "看看你有多上头",
            bgImage: "tpl_single",
            badge: "上头",
            gradient: ["FF8FA3", "FF6B8A"]
        ),
        DiscoverFeatureCard(
            templateId: "persona_card",
            title: "MBTI 性格盲盒",
            subtitle: "测测你是哪种类型",
            bgImage: "tpl_persona",
            badge: "盲盒",
            gradient: ["9C8EFF", "7B61FF"]
        )
    ]
    
    private let feedItems: [DiscoverFeedItem] = [
        DiscoverFeedItem(templateId: "office_survival", title: "你的办公室生存指数有多高？", summary: "打工人必测，看看你能活几集！", author: "整活局小编", usageCount: 73000, cover: "tpl_persona"),
        DiscoverFeedItem(templateId: "group_judge", title: "群聊判决书：谁该请奶茶？", summary: "群聊里翻车？一张判决书送你出道。", author: "梗王协会", usageCount: 58000, cover: "tpl_judge"),
        DiscoverFeedItem(templateId: "rich_card", title: "谁是这群人里的隐藏富豪？", summary: "平时装穷的最有钱，不信投个票看看。", author: "财富鉴定中心", usageCount: 124000, cover: "tpl_rich"),
        DiscoverFeedItem(templateId: "stay_up", title: "今晚谁修仙最厉害？", summary: "凌晨三点，朋友圈还在线的那个人是谁。", author: "夜猫子联盟", usageCount: 98000, cover: "tpl_stay_up"),
        DiscoverFeedItem(templateId: "truth_dare", title: "真心话大冒险卡组", summary: "聚会神器，挑战完友谊还能不能续？", author: "派对策划师", usageCount: 41000, cover: "tpl_truth_dare"),
        DiscoverFeedItem(templateId: "boss_card", title: "谁最有老板气质？", summary: "今天的画饼大王是哪位选手。", author: "工位日记", usageCount: 36000, cover: "tpl_boss")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    headerBar
                    sectionTitle(title: "热门推荐", emoji: "🔥")
                    featureSlider
                    sectionTitle(title: "正在被疯转", emoji: "✨")
                    feedList
                    Spacer(minLength: 110)
                }
            }
            .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        }
    }
    
    private var headerBar: some View {
        HStack {
            Text("发现")
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(.themeTextMain)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private func sectionTitle(title: String, emoji: String) -> some View {
        HStack(spacing: 6) {
            Text(emoji)
            Text(title)
                .font(.system(size: 17, weight: .heavy))
                .foregroundColor(.themeTextMain)
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    private var featureSlider: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(featureCards) { item in
                    if let template = MockData.template(id: item.templateId) {
                        NavigationLink(destination: TemplateDetailView(template: template)) {
                            featureCard(item)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        featureCard(item)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func featureCard(_ item: DiscoverFeatureCard) -> some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                gradient: Gradient(colors: item.gradient.map { Color(hex: $0) }),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image.bundle(item.bgImage)
                .resizable()
                .scaledToFit()
                .frame(width: 140)
                .opacity(0.45)
                .offset(x: 110, y: -10)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(item.badge)
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(.themeTextMain)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.85))
                    .cornerRadius(8)
                Spacer()
                Text(item.title)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                Text(item.subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10))
                    Text("立即生成")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.themeTextMain)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white)
                .cornerRadius(14)
            }
            .padding(16)
        }
        .frame(width: 240, height: 200)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var feedList: some View {
        VStack(spacing: 12) {
            ForEach(feedItems) { item in
                if let template = MockData.template(id: item.templateId) {
                    NavigationLink(destination: TemplateDetailView(template: template)) {
                        feedRow(item: item)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    feedRow(item: item)
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func feedRow(item: DiscoverFeedItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.08))
                    .frame(width: 88, height: 88)
                Image.bundle(item.cover)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.themeTextMain)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(item.summary)
                    .font(.system(size: 12))
                    .foregroundColor(.themeTextSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 2)
                HStack(spacing: 6) {
                    Text(item.author)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "7B61FF"))
                    Text("·")
                        .foregroundColor(.themeTextSecondary)
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Color(hex: "FF6B8A"))
                        Text("\(formatCount(item.usageCount)) 人生成")
                            .font(.system(size: 11))
                            .foregroundColor(.themeTextSecondary)
                    }
                }
            }
            
            Spacer()
            
            VStack {
                Text("去生成")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.themeTextMain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.themePrimary)
                    .cornerRadius(14)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 10000 {
            return String(format: "%.1fw", Double(count) / 10000.0)
        }
        return "\(count)"
    }
}
