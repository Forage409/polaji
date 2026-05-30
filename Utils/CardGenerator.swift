import Foundation

class CardGenerator {
    static let shared = CardGenerator()
    
    func generate(templateId: String, inputs: [String: String]) -> GeneratedCard {
        let nickname = inputs["nickname"]?.isEmpty == false ? inputs["nickname"]! : "神秘人"
        let tone = inputs["tone"] ?? "默认"
        let multiSelect = (inputs["multiSelect"] ?? "").components(separatedBy: ",").filter { !$0.isEmpty }
        let singleSelect1 = inputs["singleSelect1"] ?? ""
        let singleSelect2 = inputs["singleSelect2"] ?? ""
        let participantsStr = inputs["participants"] ?? ""
        let participants = participantsStr.isEmpty ? [] : participantsStr.components(separatedBy: ",")
        
        let id = UUID().uuidString
        let date = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
        
        var title = ""
        var subtitle = ""
        var imageName = "cover_persona"
        var stats: [StatItem] = []
        var quote = ""
        var evidenceList: [String] = []
        var resultLevel = ""
        var finalComment = ""
        var templateType = "diagnostic" // diagnostic, rank, verdict, task
        
        switch templateId {
        case "rich_card":
            templateType = "diagnostic"
            imageName = "tpl_rich"
            let isCute = tone == "可爱夸夸"
            let isToxic = tone == "毒舌吐槽"
            
            let titles = ["福布斯在逃首富", "隐形财阀继承人", "低调的亿万富翁", "民间财神爷", "钞能力觉醒者", "伪装破产的总裁", "全村的希望", "行走的印钞机", "深藏不露的大佬", "钱包厚度超标者"]
            title = titles.randomElement()!
            
            let subtitles = ["经鉴定，\(nickname) 具有严重的富豪倾向", "藏不住了，\(nickname) 的财富光芒", "震惊！\(nickname) 居然这么有钱", "我们中出了一个土豪：\(nickname)"]
            subtitle = subtitles.randomElement()!
            
            stats = [
                StatItem(name: "财富隐藏度", value: Int.random(in: 80...100)),
                StatItem(name: "消费潜力", value: Int.random(in: 70...99)),
                StatItem(name: "暴富指数", value: Int.random(in: 85...100))
            ]
            
            evidenceList = multiSelect.map { "日常表现：\($0)" }
            if evidenceList.isEmpty { evidenceList = ["日常表现：深藏不露，无法查证", "消费习惯：表面买打折，背地买大牌", "资产状况：余额比手机号还长"] }
            
            let levels = ["S级财神", "A级富豪", "SSR级金主", "黑金级VVIP"]
            resultLevel = levels.randomElement()!
            
            let comments = [
                "平时装穷，点外卖从不看价格。苟富贵，勿相忘！",
                "建议立刻交出你的财富密码！",
                "别装了，你的气质已经出卖了你的银行卡余额。",
                "这就是大佬的世界吗？我酸了。"
            ]
            finalComment = isCute ? "太棒啦，以后就靠你带我飞了！" : (isToxic ? "一天天就知道装穷，其实富得流油！" : comments.randomElement()!)
            quote = "“钱对我来说只是一个数字”"
            
        case "single_card":
            templateType = "diagnostic"
            imageName = "tpl_single_transparent"
            let titles = ["顶级桃花绝缘体", "恋爱区终身VIP", "心动刺客", "寡王之王", "纯爱战神觉醒", "海域管理员", "佛系修仙者", "浪漫过敏体质", "丘比特的黑名单", "野生单身图鉴"]
            title = titles.randomElement()!
            
            subtitle = "关于 \(nickname) 的脱单体检报告"
            
            stats = [
                StatItem(name: "桃花运", value: Int.random(in: 10...99)),
                StatItem(name: "心动阈值", value: Int.random(in: 70...100)),
                StatItem(name: "脱单概率", value: Int.random(in: 1...90))
            ]
            
            evidenceList = [
                "当前状态：\(singleSelect1)",
                "社交风格：\(singleSelect2)",
                "恋爱人格：\(["智者不入爱河", "浪漫至死不渝", "随缘即可", "主动出击"].randomElement()!)"
            ]
            
            resultLevel = ["万年单身狗", "未来海王", "随时脱单", "建议出家"].randomElement()!
            
            let comments = [
                "一个人也挺好，除了偶尔想吃第二份半价。",
                "你的桃花可能迷路了，建议开个导航。",
                "保持现在的状态，你将无坚不摧！",
                "爱情可能会迟到，但外卖不会。"
            ]
            finalComment = comments.randomElement()!
            quote = "“只要我跑得够快，爱情就追不上我”"
            
        case "stay_up":
            templateType = "diagnostic"
            imageName = "tpl_stay_up"
            let titles = ["熬夜总冠军", "深夜修仙大能", "凌晨三点的王", "褪黑素绝缘体", "修仙界天花板", "眼袋收割机", "月亮不睡我不睡", "夜行动物", "修仙党领袖", "爆肝狂魔"]
            title = titles.randomElement()!
            subtitle = "\(nickname) 的深夜活动观察报告"
            
            stats = [
                StatItem(name: "黑眼圈深度", value: Int.random(in: 85...100)),
                StatItem(name: "修仙境界", value: Int.random(in: 70...99)),
                StatItem(name: "发量危机", value: Int.random(in: 50...100))
            ]
            
            evidenceList = multiSelect.map { "修仙动因：\($0)" }
            if evidenceList.isEmpty { evidenceList = ["修仙动因：白天不懂夜的黑", "睡眠状况：深度失眠", "精神状态：异常亢奋"] }
            evidenceList.append("目前状态：\(singleSelect1)")
            
            resultLevel = ["元婴期", "渡劫期", "飞升期", "仙尊"].randomElement()!
            
            let comments = [
                "再熬一天，就能在白天看到星星了。",
                "护肝片买了吗？别光顾着修仙。",
                "你的眼袋已经比眼睛大了，睡吧！",
                "建议申请世界熬夜非物质文化遗产。"
            ]
            finalComment = comments.randomElement()!
            quote = "“生前何必久睡，死后自会长眠”"
            
        case "boss_card":
            templateType = "diagnostic"
            imageName = "tpl_boss_transparent"
            let titles = ["天生老板命", "职场PUA大师", "画饼艺术家", "气场两米八", "天选打工人杀手", "未来霸总", "精神资本家", "职场卷王之王", "PPT魔术师", "格局打开者"]
            title = titles.randomElement()!
            subtitle = "\(nickname) 的老板气质鉴定"
            
            stats = [
                StatItem(name: "画饼能力", value: Int.random(in: 80...100)),
                StatItem(name: "威严霸气", value: Int.random(in: 70...99)),
                StatItem(name: "压榨潜力", value: Int.random(in: 50...90))
            ]
            
            evidenceList = multiSelect.map { "显著特征：\($0)" }
            if evidenceList.isEmpty { evidenceList = ["显著特征：走路带风", "口头禅：辛苦了", "做事风格：雷厉风行"] }
            evidenceList.append("案发场景：\(singleSelect1)")
            
            resultLevel = ["资深资本家", "初级包工头", "画饼学博士", "霸总附体"].randomElement()!
            
            let comments = [
                "每天都在发愁，这几百亿的项目该交给谁。",
                "听懂掌声！你的格局已经太大了。",
                "建议立刻去注册公司，别耽误了才华。",
                "打工人看了你都瑟瑟发抖。"
            ]
            finalComment = comments.randomElement()!
            quote = "“明年给大家换个更好的大饼”"
            
        case "group_judge":
            templateType = "verdict"
            imageName = "icon_judge"
            let defendantInput = inputs["defendant"] ?? "某人"
            let titles = ["最高群聊法院判决书", "友谊法庭通缉令", "鸽王审判大厅", "群聊制裁决议", "人间真实判决书", "友尽边缘警告", "一级逮捕令", "终极审判书", "正义铁拳裁决", "友谊的小船翻了"]
            title = titles.randomElement()!
            subtitle = "被告人：\(defendantInput)"
            
            stats = [
                StatItem(name: "罪恶值", value: Int.random(in: 80...100)),
                StatItem(name: "嚣张度", value: Int.random(in: 50...90))
            ]
            
            evidenceList = multiSelect.map { "主要罪行：\($0)" }
            if evidenceList.isEmpty { evidenceList = ["主要罪行：潜水不冒泡", "次要罪行：表情包太少", "作案动机：太懒了"] }
            evidenceList.append("作案现场：\(singleSelect1)")
            
            resultLevel = ["十恶不赦", "罪无可恕", "建议拉黑", "留校察看"].randomElement()!
            
            finalComment = "经群主和全体群友一致裁定，判决如下：\n立刻【\(singleSelect2)】，不得上诉！"
            quote = "“正义也许会迟到，但惩罚绝不缺席！”"
            
        case "friend_vote":
            templateType = "rank"
            imageName = "icon_vote"
            let topic = inputs["topic"] ?? "神秘榜单"
            let titles = ["友谊破碎排行榜", "群聊风云榜", "塑料姐妹花/兄弟情榜", "不接受反驳排行榜", "年度最佳大赏", "内部爆料榜", "公开处刑榜", "谁最离谱排行榜", "人间清醒榜", "全网最准排行榜"]
            title = titles.randomElement()!
            subtitle = "评选主题：\(topic)"
            
            stats = []
            
            // Generate ranking
            var shuffledParticipants = participants.shuffled()
            if shuffledParticipants.isEmpty { shuffledParticipants = ["路人甲", "路人乙", "路人丙"] }
            
            for (index, person) in shuffledParticipants.enumerated() {
                let rank = index + 1
                let score = 100 - (index * Int.random(in: 10...20))
                evidenceList.append("TOP \(rank) : \(person) (\(score)票)")
            }
            
            resultLevel = "年度最具争议榜单"
            let comments = ["群众的眼睛是雪亮的！", "这结果不服不行！", "第一名实至名归，请自觉请客！", "这就是民意，别挣扎了！"]
            finalComment = comments.randomElement()!
            quote = "“榜单仅供娱乐，打架概不负责”"
            
        case "truth_dare":
            templateType = "task"
            imageName = "icon_truth_dare"
            let mode = singleSelect1
            let titles = ["命运的齿轮开始转动", "社死挑战书", "灵魂拷问室", "危险游戏", "勇敢者的试炼", "尖叫之夜", "破冰狂欢", "心跳加速局", "塑料友谊测试", "不准撒谎不准逃"]
            title = titles.randomElement()!
            subtitle = mode == "随机" ? ["真心话", "大冒险"].randomElement()! : mode
            
            stats = [
                StatItem(name: "社死指数", value: Int.random(in: 50...100)),
                StatItem(name: "心跳飙升", value: Int.random(in: 60...100))
            ]
            
            let difficulty = singleSelect2
            let isTruth = subtitle == "真心话"
            
            let truthTasks = [
                "说出一个你至今未向别人透露过的秘密",
                "分享你最近一次哭泣的原因",
                "在场的人中，你对谁的第一印象和现在反差最大？",
                "你做过最丢脸的一件事是什么？",
                "说出你手机里最不想让人看到的一张照片的内容"
            ]
            
            let dareTasks = [
                "用尽全力模仿大猩猩锤胸口，持续10秒",
                "随机找列表第7个异性发一句'我想你了'",
                "深情地对着墙壁表白一分钟",
                "跳一段你最拿手的广场舞或女团舞",
                "发一条朋友圈说'我是猪'，保持十分钟"
            ]
            
            let task = isTruth ? truthTasks.randomElement()! : dareTasks.randomElement()!
            
            evidenceList = [
                "任务目标：\(nickname.isEmpty ? "抽取者" : nickname)",
                "难度评级：\(difficulty)",
                "执行内容：\(task)"
            ]
            
            resultLevel = isTruth ? "坦白从宽" : "抗拒从严"
            finalComment = "愿赌服输，气氛组就靠你了！不要试图逃避惩罚哦！"
            quote = "“玩得起，放得下”"
            
        default:
            templateType = "diagnostic"
            imageName = "cover_persona"
            title = "今日专属人设卡"
            subtitle = "\(nickname) 的灵魂诊断报告"
            stats = [StatItem(name: "可爱度", value: 99), StatItem(name: "战斗力", value: 88)]
            evidenceList = ["日常表现：优秀", "情绪状态：稳定发疯"]
            resultLevel = "SSR级稀有生物"
            finalComment = "做人嘛，最重要的是开心。"
            quote = "“今天也是元气满满的一天呢”"
        }
        
        return GeneratedCard(
            id: id,
            templateId: templateId,
            title: title,
            subtitle: subtitle,
            mainImageName: imageName,
            stats: stats,
            quote: quote,
            evidenceList: evidenceList,
            resultLevel: resultLevel,
            finalComment: finalComment,
            styleTone: tone,
            participants: participants,
            templateType: templateType,
            createdAt: date
        )
    }
}
