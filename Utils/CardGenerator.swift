import Foundation

class CardGenerator {
    static let shared = CardGenerator()
    
    func generate(templateId: String, inputs: [String: String]) -> GeneratedCard {
        let nickname = inputs["nickname"] ?? "用户"
        let id = UUID().uuidString
        let date = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none)
        
        var title = ""
        var subtitle = ""
        var imageName = "banner_character"
        var stats: [StatItem] = []
        var quote = ""
        
        switch templateId {
        case "office_survival":
            title = "办公室生存大师"
            subtitle = "在工位上如老狗，在内心里自由冲浪"
            imageName = "icon_persona"
            stats = [
                StatItem(name: "生存能力", value: Int.random(in: 60...99)),
                StatItem(name: "摸鱼技巧", value: Int.random(in: 80...100)),
                StatItem(name: "抗压能力", value: Int.random(in: 50...95)),
                StatItem(name: "社交电量", value: Int.random(in: 5...40))
            ]
            quote = "上班是为了下班更快乐，我的工位，我做主！"
            
        case "group_judge":
            let defendant = inputs["defendant"] ?? "某人"
            title = "群聊判决书"
            subtitle = "被告：\(defendant)"
            imageName = "icon_judge"
            stats = [
                StatItem(name: "有罪指数", value: Int.random(in: 80...100)),
                StatItem(name: "嚣张程度", value: Int.random(in: 50...90))
            ]
            let punishment = inputs["punishment"] ?? "请全群喝奶茶"
            quote = "判决结果：\(punishment)一次，立即执行。不接受狡辩！"
            
        case "friend_vote":
            let topic = inputs["topic"] ?? "投票局"
            title = "好朋友排行榜"
            subtitle = "关于「\(topic)」的最终结果"
            imageName = "icon_vote"
            stats = [
                StatItem(name: "支持率", value: Int.random(in: 60...95)),
                StatItem(name: "离谱程度", value: Int.random(in: 50...99))
            ]
            quote = "群众的眼睛是雪亮的，不要试图掩饰！"
            
        case "truth_dare":
            title = "真心话大冒险"
            subtitle = "勇者的试炼"
            imageName = "icon_truth_dare"
            stats = [
                StatItem(name: "心跳指数", value: Int.random(in: 80...100)),
                StatItem(name: "社死概率", value: Int.random(in: 50...99))
            ]
            quote = "愿赌服输，气氛组就靠你了！"
            
        case "rich_card":
            title = "隐藏富豪鉴定卡"
            subtitle = "经鉴定：绝对是有钱人"
            imageName = "tpl_rich"
            stats = [
                StatItem(name: "财富隐藏度", value: Int.random(in: 80...100)),
                StatItem(name: "消费潜力", value: Int.random(in: 70...95))
            ]
            quote = "平时装穷，点外卖从不看价格。苟富贵，勿相忘！"
            
        case "stay_up":
            title = "熬夜冠军证书"
            subtitle = "月亮不睡我不睡"
            imageName = "tpl_stay_up"
            stats = [
                StatItem(name: "黑眼圈深度", value: Int.random(in: 85...100)),
                StatItem(name: "修仙境界", value: Int.random(in: 70...99))
            ]
            quote = "再熬一天，就能在白天看到星星了。"
            
        case "single_card":
            title = "寡王鉴定书"
            subtitle = "单身不仅靠实力，还靠运气"
            imageName = "tpl_single_transparent"
            stats = [
                StatItem(name: "孤单指数", value: Int.random(in: 80...100)),
                StatItem(name: "桃花免疫", value: Int.random(in: 60...99))
            ]
            quote = "一个人也挺好，除了偶尔想吃第二份半价。"
            
        case "boss_card":
            title = "天生老板命"
            subtitle = "气质这块拿捏得死死的"
            imageName = "tpl_boss_transparent"
            stats = [
                StatItem(name: "画大饼能力", value: Int.random(in: 80...100)),
                StatItem(name: "威严指数", value: Int.random(in: 70...99))
            ]
            quote = "每天都在发愁，这几百亿的项目该交给谁。"
            
        case "persona_card":
            let mood = inputs["mood"] ?? "平静"
            title = "今日状态档案"
            subtitle = "心情：\(mood)"
            imageName = "icon_persona"
            stats = [
                StatItem(name: "精神力", value: Int.random(in: 10...90)),
                StatItem(name: "食欲", value: Int.random(in: 50...100))
            ]
            quote = "做人嘛，最重要的是开心。"
            
        default:
            title = "整活局通用卡片"
            subtitle = "你的专属定制"
            imageName = "logo"
            stats = [
                StatItem(name: "欢乐指数", value: Int.random(in: 80...100))
            ]
            quote = "和朋友一起整活，好玩又有梗！"
        }
        
        return GeneratedCard(id: id, templateId: templateId, title: title, subtitle: subtitle, mainImageName: imageName, stats: stats, quote: quote, createdAt: date)
    }
}
