import Foundation

class CardGenerator {
    static let shared = CardGenerator()
    
    func generate(templateId: String, inputs: [String: String]) -> GeneratedCard {
        let nickname = inputs["nickname"]?.isEmpty == false ? inputs["nickname"]! : "神秘网友"
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
        var templateType = "diagnostic"
        
        switch templateId {
        case "rich_card":
            templateType = "diagnostic"
            imageName = "tpl_rich"
            let titles = ["野生财神爷", "隐形ATM机", "装穷表演艺术家", "全村的希望", "钞能力绝缘体"]
            title = titles.randomElement()!
            subtitle = "关于 \(nickname) 的财富基因检测"
            
            stats = [
                StatItem(name: "财富掩饰力", value: Int.random(in: 80...100)),
                StatItem(name: "真实财力", value: Int.random(in: 70...99)),
                StatItem(name: "请客概率", value: Int.random(in: 1...15))
            ]
            
            if multiSelect.isEmpty {
                evidenceList = ["日常表现：深藏不露", "消费习惯：只买贵的", "口头禅：真没钱了"]
            } else {
                evidenceList = multiSelect.map { "日常表现：\($0)" }
            }
            
            resultLevel = ["V50看看实力", "隐藏金主爸爸", "伪装破产", "真穷（确信）"].randomElement()!
            
            if tone == "可爱夸夸" {
                finalComment = "太厉害啦，简直是行走的印钞机！以后抱紧你的大腿！"
                quote = "富贵苟，勿相忘，明天V我50尝尝咸淡"
            } else if tone == "毒舌吐槽" {
                finalComment = "一天天就知道喊穷，其实背地里偷偷发大财，已老实，求放过。"
                quote = "你这不是装穷，你这是诈骗！"
            } else {
                finalComment = "经鉴定，该同志具有极高暴富潜力，建议立刻上交工资卡。"
                quote = "表面上骑共享单车，背地里全款拿下海景房"
            }
            
        case "single_card":
            templateType = "diagnostic"
            imageName = "tpl_single_transparent"
            title = ["纯爱战神应声倒地", "寡王本王", "智者不入爱河", "海域管理员", "母胎SOLO金奖"].randomElement()!
            subtitle = "\(nickname) 的脱单体检报告"
            
            stats = [
                StatItem(name: "心动阈值", value: Int.random(in: 80...100)),
                StatItem(name: "桃花免疫力", value: Int.random(in: 70...99)),
                StatItem(name: "孤寡指数", value: Int.random(in: 90...100))
            ]
            
            evidenceList = [
                "感情状态：\(singleSelect1)",
                "社交打法：\(singleSelect2)",
                "核心病因：\(["太宅了", "沉迷搞钱", "眼光太高", "月老牵的钢筋被你掰断了"].randomElement()!)"
            ]
            
            resultLevel = ["建议出家", "水泥封心", "随时脱单", "海王苗子"].randomElement()!
            
            if tone == "甜甜鼓励" {
                finalComment = "不要着急嘛，最好的总是压轴出场，对的人已经在路上了哦！"
                quote = "单身只是为了积攒运气遇见最好的你"
            } else if tone == "毒舌吐槽" {
                finalComment = "你的桃花不是没开，是连根都烂了。建议去庙里烧高香。"
                quote = "只要我跑得够快，爱情的苦就追不上我"
            } else {
                finalComment = "这不叫单身，这叫战略性防御。保持现状，你将无坚不摧。"
                quote = "爱情可能会迟到，但外卖一定按时送达"
            }
            
        case "stay_up":
            templateType = "diagnostic"
            imageName = "tpl_stay_up"
            title = ["脆皮修仙党", "褪黑素绝缘体", "深夜 emo 大师", "眼袋大户", "肝帝觉醒"].randomElement()!
            subtitle = "\(nickname) 的深夜存活观察"
            
            stats = [
                StatItem(name: "黑眼圈深度", value: Int.random(in: 85...100)),
                StatItem(name: "发量危机", value: Int.random(in: 70...99)),
                StatItem(name: "精神状态", value: Int.random(in: 1...10))
            ]
            
            evidenceList = multiSelect.map { "修仙动因：\($0)" }
            if evidenceList.isEmpty { evidenceList = ["修仙动因：不舍得睡", "睡眠状况：薛定谔的困", "精神状态：异常亢奋"] }
            evidenceList.append("当前血量：\(singleSelect1)")
            
            resultLevel = ["元婴期大能", "极度危险", "建议就医", "神仙难救"].randomElement()!
            
            if tone == "扎心" {
                finalComment = "照照镜子看看你的发际线，再熬下去可以直接去演清朝戏了。"
                quote = "你熬的不是夜，是你的寿命"
            } else if tone == "搞笑" {
                finalComment = "再熬一天，你就能在白天看见星星了，顺便还能跟太奶打个招呼。"
                quote = "生前何必久睡...啊呸，赶紧给我去睡觉！"
            } else {
                finalComment = "乖，放下手机去睡觉吧，身体才是革命的本钱呀。"
                quote = "月亮不睡我不睡，我是秃头小宝贝"
            }
            
        case "boss_card":
            templateType = "diagnostic"
            imageName = "tpl_boss_transparent"
            title = ["天选资本家", "画饼学教授", "职场悍匪", "精神股东", "格局打开者"].randomElement()!
            subtitle = "\(nickname) 的气场鉴定"
            
            stats = [
                StatItem(name: "画饼能力", value: Int.random(in: 80...100)),
                StatItem(name: "甩锅技巧", value: Int.random(in: 70...99)),
                StatItem(name: "PUA指数", value: Int.random(in: 50...90))
            ]
            
            evidenceList = multiSelect.map { "显著特征：\($0)" }
            if evidenceList.isEmpty { evidenceList = ["显著特征：喜欢说“收到”", "口头禅：辛苦了", "做事风格：雷厉风行"] }
            evidenceList.append("施法场景：\(singleSelect1)")
            
            resultLevel = ["资深老油条", "未来霸总", "黑心包工头", "摸鱼带师"].randomElement()!
            
            if tone == "夸张整活" {
                finalComment = "听懂掌声！你的格局已经大到冲出亚洲走向宇宙了！"
                quote = "每天都在发愁这几百亿的项目该交给谁"
            } else {
                finalComment = "打工人看了你都瑟瑟发抖，建议立刻去注册公司别耽误才华。"
                quote = "明年给大家换个更大的饼"
            }
            
        case "group_judge":
            templateType = "verdict"
            imageName = "icon_judge"
            let defendantInput = inputs["defendant"] ?? "某人"
            title = ["群聊最高法", "友尽边缘警告", "鸽王通缉令", "赛博升堂"].randomElement()!
            subtitle = "被告人：\(defendantInput)"
            
            evidenceList = multiSelect.map { "主要罪行：\($0)" }
            if evidenceList.isEmpty { evidenceList = ["主要罪行：潜水不冒泡", "次要罪行：装作没看见", "作案动机：实在太懒"] }
            evidenceList.append("案发场景：\(singleSelect1)")
            
            resultLevel = ["罪无可恕", "十恶不赦", "建议踢出群", "留校察看"].randomElement()!
            
            let punish = String(singleSelect2.prefix(10)) // Max 10 chars
            finalComment = punish.isEmpty ? "立刻发红包" : punish
            
            if tone == "离谱判决" {
                quote = "法网恢恢，疏而不漏，你也有今天！还不赶紧认罪伏法！"
            } else if tone == "毒舌判决" {
                quote = "就这点胆子还敢顶风作案？你的良心不会痛吗？"
            } else {
                quote = "经全体群友一致裁定，立即执行，不得上诉！"
            }
            
        case "friend_vote":
            templateType = "rank"
            imageName = "icon_vote"
            let topic = inputs["topic"] ?? "神秘榜单"
            title = ["塑料友谊风云榜", "谁最离谱排行榜", "人间清醒大赏", "内部爆料专区"].randomElement()!
            subtitle = "评选主题：\(topic)"
            
            var shuffledParticipants = participants.shuffled()
            if shuffledParticipants.isEmpty { shuffledParticipants = ["路人甲", "路人乙", "路人丙"] }
            
            let reasons = ["实至名归毫无悬念", "群众的眼睛是雪亮的", "平时藏得深还是被抓到了", "大家都懂的", "其实还有更离谱的没爆出来", "凭实力拿下的名次"]
            
            for (index, person) in shuffledParticipants.enumerated() {
                let rankStr = index == 0 ? "断层C位" : (index == 1 ? "险胜出道" : "遗憾陪跑")
                let reason = reasons.randomElement()!
                evidenceList.append("TOP \(index + 1): \(person) (\(rankStr)) - \(reason)")
            }
            
            resultLevel = "年度最具争议榜单"
            if tone == "友情伤害榜" {
                finalComment = "这结果太扎心了，建议榜首立刻请全群喝奶茶以平民愤！"
            } else {
                finalComment = "这份榜单绝对公平公正公开（假的），不服憋着！"
            }
            
        case "truth_dare":
            templateType = "task"
            imageName = "icon_truth_dare"
            let mode = singleSelect1
            title = ["赛博真心话", "社死大冒险", "危险边缘试探", "命运大转盘"].randomElement()!
            subtitle = mode == "随机" ? ["真心话", "大冒险"].randomElement()! : mode
            
            let difficulty = singleSelect2
            let isTruth = subtitle == "真心话"
            
            let truthTasks = [
                "说出一个你至今未向别人透露过的尴尬秘密",
                "在场的人里，如果必须选一个当对象你会选谁？",
                "你最近一次搜索记录是什么，立刻念出来",
                "坦白你做过最绿茶/渣男的一件事",
                "你手机里最不想让人看到的一张照片是什么内容？"
            ]
            
            let dareTasks = [
                "用尽全力模仿大猩猩锤胸口，并大喊三声我是猴王",
                "随机找列表第7个异性发一句'我想你了'，截图为证",
                "深情地对着墙壁表白一分钟",
                "跳一段你最拿手的土味摇花手",
                "发一条朋友圈说'我是猪'，保持十分钟不能删"
            ]
            
            let task = isTruth ? truthTasks.randomElement()! : dareTasks.randomElement()!
            
            evidenceList = [
                "目标玩家：\(nickname.isEmpty ? "抽取者" : nickname)",
                "挑战难度：\(difficulty)",
                "执行内容：\(task)",
                "失败惩罚：连喝三杯 / 发200元大红包"
            ]
            
            resultLevel = isTruth ? "坦白从宽" : "抗拒从严"
            finalComment = "愿赌服输，群众的眼睛盯着你呢，别想耍赖逃跑！"
            quote = "气氛组已就位，请开始你的表演"
            
        default:
            templateType = "diagnostic"
            imageName = "icon_persona"
            title = "今日打工人设"
            subtitle = "\(nickname) 的灵魂诊断"
            stats = [StatItem(name: "可爱度", value: 99), StatItem(name: "发疯指数", value: 100)]
            evidenceList = ["日常表现：优秀", "情绪状态：随时崩溃"]
            resultLevel = "绝版稀有生物"
            
            if tone == "毒舌吐槽" {
                finalComment = "这就是你的实力吗？不过如此！"
                quote = "今天又是被生活毒打的一天"
            } else {
                finalComment = "做人嘛最重要的是开心，不管怎样你都是最棒的！"
                quote = "今天也是元气满满的打工人呢"
            }
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
