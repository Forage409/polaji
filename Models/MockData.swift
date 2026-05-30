import Foundation

@MainActor
struct MockData {
    static var allTemplates: [Template] = [
        Template(id: "persona_card", name: "今日人设卡", category: "人设卡", description: "生成你今天的专属人设", coverImage: "cover_persona", isVip: false, usageCount: 24, tags: ["日常", "整活"], fields: []),
        Template(id: "group_judge", name: "群聊判官", category: "判官", description: "看看谁该请奶茶", coverImage: "cover_judge", isVip: false, usageCount: 15, tags: ["群聊", "互动"], fields: []),
        Template(id: "friend_vote", name: "好友投票局", category: "投票", description: "看看谁最会...", coverImage: "cover_vote", isVip: false, usageCount: 18, tags: ["投票", "好友"], fields: []),
        Template(id: "truth_dare", name: "真心话大冒险", category: "趣味", description: "和朋友玩点刺激的", coverImage: "cover_truth_dare", isVip: false, usageCount: 9, tags: ["刺激", "聚会"], fields: []),
        Template(id: "rich_card", name: "谁最像隐藏富豪？", category: "投票", description: "测测谁是真土豪", coverImage: "cover_rich", isVip: false, usageCount: 12, tags: ["搞钱"], fields: []),
        Template(id: "stay_up", name: "谁最会熬夜？", category: "投票", description: "修仙党必备", coverImage: "cover_stay_up", isVip: false, usageCount: 9, tags: ["熬夜"], fields: []),
        Template(id: "single_card", name: "谁最容易脱单？", category: "投票", description: "看看桃花运在谁那", coverImage: "cover_single", isVip: false, usageCount: 8, tags: ["恋爱"], fields: []),
        Template(id: "boss_card", name: "谁最像老板？", category: "投票", description: "天生老板命", coverImage: "cover_boss", isVip: false, usageCount: 7, tags: ["职场"], fields: []),
        Template(id: "office_survival", name: "办公室生存大师", category: "人设卡", description: "生成你的专属办公室人设", coverImage: "cover_persona", isVip: false, usageCount: 12, tags: ["职场", "打工人"], fields: [])
    ]
    
    static var hotTemplates: [Template] {
        Array(allTemplates.filter { $0.category == "投票" }.prefix(4))
    }
    
    static var recentWorks: [Work] = []
    
    static func template(id: String) -> Template? {
        allTemplates.first(where: { $0.id == id })
    }
    
    static var quickCreateTemplates: [Template] {
        ["persona_card", "group_judge", "friend_vote", "truth_dare"]
            .compactMap { template(id: $0) }
    }
    
    static func updateUsageCounts(from remoteTemplates: [RemoteTemplate]) {
        for (index, template) in allTemplates.enumerated() {
            if let remote = remoteTemplates.first(where: { $0.id == template.id }) {
                allTemplates[index].usageCount = remote.usageCount
            }
        }
    }
}
