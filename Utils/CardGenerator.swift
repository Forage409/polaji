import Foundation

class CardGenerator {
    static let shared = CardGenerator()
    
    let commonSoftRoasts = [
        "这波很难不让人怀疑",
        "别装了，群友都看见了",
        "看似普通，实则很有东西",
        "这不是巧合，这是稳定发挥",
        "建议把这件事当个事儿办",
        "表面风平浪静，背地里全是细节",
        "这把属于轻松拿捏",
        "你说没事，但数据不是这么说的",
        "证据不多，但每一条都很关键",
        "先别急着解释，越解释越像真的",
        "这状态基础，能撑到现在就不基础",
        "主打一个看破不说破",
        "情绪价值给到了，节目效果也给到了",
        "这不是人设，这是日常泄露",
        "群聊可以沉默，但截图不会说谎",
        "看起来随便，其实很会",
        "离谱但合理，抽象但成立",
        "懂的人已经开始笑了",
        "有点东西，但不完全承认",
        "建议保留解释权，但别抱太大希望"
    ]
    
    let tonePrefixes: [String: [String]] = [
        "serious": [
            "经综合观察，",
            "从当前表现来看，",
            "本次结果显示，",
            "结合现有线索，"
        ],
        "funny": [
            "群友先别笑，",
            "这波很难评，",
            "截图先别删，",
            "懂的人已经在点头，"
        ],
        "cute": [
            "先夸一句，",
            "小问题不大，",
            "这也太可爱了，",
            "别紧张，是好事，"
        ],
        "sharp": [
            "别装了，",
            "先别急着解释，",
            "你这个操作，",
            "有一说一，"
        ],
        "absurd": [
            "事情开始抽象了，",
            "这局像是系统随机发牌，",
            "合理中带点离谱，",
            "建议立刻开个小会，"
        ]
    ]

    func generate(templateId: String, inputs: [String: String]) -> GeneratedCard {
        let nickname = inputs["nickname"]?.isEmpty == false ? inputs["nickname"]! : "神秘网友"
        let toneInput = inputs["tone"] ?? "默认"
        let multiSelect = (inputs["multiSelect"] ?? "").components(separatedBy: ",").filter { !$0.isEmpty }
        let singleSelect1 = inputs["singleSelect1"] ?? ""
        _ = inputs["singleSelect2"] ?? ""
        let participantsStr = inputs["participants"] ?? ""
        let participants = participantsStr.isEmpty ? [] : participantsStr.components(separatedBy: ",")
        
        let id = UUID().uuidString
        let date = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
        
        var title = ""
        var subtitle = ""
        var imageName = "cover_persona"
        var stats: [StatItem] = []
        var quote = commonSoftRoasts.randomElement() ?? ""
        var evidenceList: [String] = []
        var resultLevel = ""
        var finalComment = ""
        var templateType = "diagnostic"
        
        // Map UI tone to internal tone category
        var toneCategory = "funny"
        if toneInput.contains("正经") || toneInput.contains("认真") { toneCategory = "serious" }
        else if toneInput.contains("可爱") || toneInput.contains("甜甜") || toneInput.contains("温柔") { toneCategory = "cute" }
        else if toneInput.contains("毒舌") || toneInput.contains("扎心") { toneCategory = "sharp" }
        else if toneInput.contains("离谱") || toneInput.contains("夸张") { toneCategory = "absurd" }
        
        let tonePrefix = tonePrefixes[toneCategory]?.randomElement() ?? ""
        
        switch templateId {
        case "rich_card":
            templateType = "diagnostic"
            imageName = "tpl_rich"
            let richTitles = ["低调富豪观察报告", "隐藏财力鉴定", "来财体质检测中", "钱包深度可疑报告", "平民伪装失败现场", "低调但不完全低调", "疑似富豪体验生活", "花钱淡定指数报告", "嘴上没钱行为很贵", "隐藏资产雷达启动", "消费习惯异常样本", "富贵气息泄露记录"]
            let richSubtitles = ["表面说随便，细节全是预算外", "嘴上喊穷，操作一点都不穷", "看似普通路人，实则消费很稳", "钱不一定多，但花得确实淡定", "不是炫富，是不小心露了点细节", "低调是低调，但群友不是瞎的", "每次说没钱，下一秒开始下单", "贫穷只是台词，消费才是证据", "这波不像没钱，像在体验生活", "看起来不显眼，但支付动作很丝滑"]
            let richEvidence = ["说没钱的时候很熟练，付款的时候也很熟练", "点东西不看满减，仿佛优惠券只是装饰", "嘴上说随便，实际审美一点不随便", "每次请客都说小事，听起来更可疑了", "装备更新速度明显超过普通人类", "平时很低调，但消费记录不太配合", "别人还在纠结价格，他已经在看颜色了", "花钱没有大动作，但细节很像有底气", "从不主动炫耀，但总能在关键时刻露一手", "说自己很穷，却总能刚好买到想要的", "不争不抢，但结账速度很有压迫感", "看似省钱，实际只是懒得解释", "每次都说下次再买，结果下次已经到了", "对价格没有情绪波动，疑似见过大场面", "不一定真的富，但气质已经先富起来了", "购物车像愿望清单，付款像日常任务", "表面冷静，背后可能早就做好功课", "不像冲动消费，像稳定补货", "钱包没说话，但行为很诚实", "这人不是乱花钱，是花得很像有规划"]
            let richLevels = ["轻度可疑", "低调玩家", "疑似有矿", "来财体质", "隐藏富豪", "平民伪装", "预算外选手", "钱包深不可测"]
            let richFinals = ["建议继续观察，此人可能只是懒得解释自己的消费观", "群友一致认为：你不是没钱，你是低调", "本次鉴定不保证准确，但可疑程度已经拉满", "如果这是伪装，那伪装得有点太丝滑了", "你的钱包可能很安静，但行为已经替它发言了", "你可以继续说没钱，大家可以继续假装相信", "这不是炫富，这是生活细节自动曝光", "建议把贫穷人设先收一收，证据有点多", "真正的富豪不一定高调，但一定很会淡定付款", "最终结论：不是一定有钱，但确实不像很缺"]

            title = richTitles.randomElement() ?? ""
            subtitle = richSubtitles.randomElement() ?? ""
            resultLevel = richLevels.randomElement() ?? ""
            finalComment = tonePrefix + (richFinals.randomElement() ?? "")
            stats = [StatItem(name: "财富掩饰", value: Int.random(in: 60...100)), StatItem(name: "真实财力", value: Int.random(in: 60...100)), StatItem(name: "淡定指数", value: Int.random(in: 60...100))]
            evidenceList = Array(richEvidence.shuffled().prefix(3))
            
        case "single_card":
            templateType = "diagnostic"
            imageName = "tpl_single_transparent"
            let singleTitles = ["脱单可能性观察报告", "桃花信号检测中", "感情进度条加载中", "单身状态复盘卡", "恋爱气氛可疑报告", "脱单雷达已启动", "桃花运势轻量分析", "心动预警鉴定", "暧昧气息检测报告", "恋爱可能性说明书", "嘴硬单身观察样本", "被动心动研究报告"]
            let singleSubtitles = ["不是没人喜欢，是你太会装不知道", "嘴上说随缘，细节已经开始期待", "看似佛系，实际也会偷偷在意", "脱单不一定靠玄学，但你有点机会", "别急，缘分可能在路上堵车", "你不是没有桃花，是桃花还没找到入口", "当前状态：嘴硬，心里有点动静", "朋友都看出来了，你还在装没事", "表面无所谓，实际消息提醒开得很响", "脱单进度不明，但气氛已经开始变化"]
            let singleEvidence = ["说自己不想谈，但看到甜甜的东西会停留三秒", "嘴上佛系随缘，实际对聊天频率很敏感", "朋友一提到某个人，你的反应速度明显变快", "表面很冷静，实际已经开始脑补小剧场", "对别人说没兴趣，但会记住对方随口说的小事", "明明想回消息，还要先假装忙一下", "不主动，但也不是完全不期待", "社交电量不高，但对特定的人会自动充电", "看似单身稳定，实际容易被细节打动", "朋友圈不发动态，但心里戏很多", "嘴上说顺其自然，手上已经开始点开聊天框", "你不是不会恋爱，你是启动速度比较慢", "别人主动一点，你就开始进入观察模式", "对恋爱没意见，主要是对尴尬有意见", "你需要的不是桃花，是一个会主动破冰的人", "暧昧苗头不是没有，只是你太会装傻", "只要对方足够自然，你其实很容易心软", "表面独立，内心也想有人一起吃第二份半价", "你不是没人追，是筛选系统比较严格", "有点想脱单，但不想显得太想"]
            let singleLevels = ["桃花待机", "轻微心动", "暧昧预备", "脱单有戏", "嘴硬选手", "被动心动", "慢热但有机会", "缘分加载"]
            let singleFinals = ["建议别太嘴硬，机会来的时候可以稍微接一下", "你不是没有机会，只是太擅长把机会聊成普通朋友", "当前脱单关键：少装一点，多接一点", "桃花不一定轰轰烈烈，也可能从一句废话开始", "你适合慢慢靠近，不适合突然上强度", "别急着否认，朋友已经看出一点苗头了", "这把不一定立刻脱单，但气氛已经有点东西", "脱单这件事，先从不逃避聊天开始", "建议保留期待，但不要把自己吓跑", "最终结论：不是没可能，是你还在观察"]

            title = singleTitles.randomElement() ?? ""
            subtitle = singleSubtitles.randomElement() ?? ""
            resultLevel = singleLevels.randomElement() ?? ""
            finalComment = tonePrefix + (singleFinals.randomElement() ?? "")
            stats = [StatItem(name: "心动阈值", value: Int.random(in: 60...100)), StatItem(name: "被动指数", value: Int.random(in: 60...100)), StatItem(name: "桃花潜能", value: Int.random(in: 60...100))]
            evidenceList = Array(singleEvidence.shuffled().prefix(3))
            
        case "stay_up":
            templateType = "diagnostic"
            imageName = "tpl_stay_up"
            let stayUpTitles = ["深夜活动观察报告", "熬夜体质检测卡", "夜行动物鉴定", "凌晨在线状态报告", "作息稳定崩坏记录", "黑眼圈浓度分析", "今晚又没早睡", "白天困晚上精神报告", "深夜清醒研究样本", "早睡失败复盘", "睡眠系统异常报告", "凌晨三点精神股东"]
            let stayUpSubtitles = ["白天像低电量，晚上突然满格", "不是不困，是手机还没同意", "早睡计划存在，但执行力正在加载", "你和睡觉之间，只差一个放下手机", "夜深了，人清醒了，事情也变多了", "白天想补觉，晚上想重开人生", "困是真的困，不睡也是真的不睡", "今晚说早睡，明晚继续说", "睡眠不是没有，只是排队排到很后面", "你不是熬夜，是和凌晨比较熟"]
            let stayUpEvidence = ["白天消息已读很慢，凌晨回复特别积极", "一到晚上，脑子开始自动开会", "明明只想刷五分钟，结果天快亮了", "早睡两个字每天都说，但从没真正上线", "白天困到怀疑人生，晚上精神到怀疑自己", "每次准备睡觉，都会突然想起一个不重要的事", "睡前仪式过长，导致睡觉本身被取消", "手机电量比本人状态更健康", "凌晨的你特别清醒，清醒到有点多余", "嘴上说睡了，在线状态还很诚实", "明天要早起，但今晚先不管明天", "刷视频不是重点，重点是停不下来", "不是没有睡意，是被信息流拦截了", "熬夜原因每天不同，结果高度一致", "晚上适合想事情，也适合后悔白天没做事", "困意来了又走，像不熟的朋友", "你和作息之间，隔着一个短视频平台", "凌晨的灵感很多，执行一般在第二天消失", "不是不想睡，是还没准备好面对明天", "早睡是目标，熬夜是惯性"]
            let stayUpLevels = ["轻度晚睡", "夜间活跃", "凌晨常驻", "作息漂移", "黑眼圈会员", "早睡困难户", "深夜清醒", "白天省电模式"]
            let stayUpFinals = ["建议今晚别立 Flag，直接把手机放远一点", "你的问题不是不困，是太会拖到下一集", "别说早睡了，先从少刷十分钟开始", "凌晨很精彩，但第二天真的会收账", "你不是夜猫子，你是白天欠的精神晚上补", "今晚适合早点睡，不适合继续研究人生", "早睡不需要仪式感，只需要狠心关屏", "如果困意来了，请不要把它送走", "熬夜可以偶尔，别让它变成默认设置", "最终结论：你不是睡不着，是太会给自己找事"]

            title = stayUpTitles.randomElement() ?? ""
            subtitle = stayUpSubtitles.randomElement() ?? ""
            resultLevel = stayUpLevels.randomElement() ?? ""
            finalComment = tonePrefix + (stayUpFinals.randomElement() ?? "")
            stats = [StatItem(name: "凌晨活跃", value: Int.random(in: 60...100)), StatItem(name: "拖延指数", value: Int.random(in: 60...100)), StatItem(name: "黑眼圈浓度", value: Int.random(in: 60...100))]
            evidenceList = Array(stayUpEvidence.shuffled().prefix(3))
            
        case "boss_card":
            templateType = "diagnostic"
            imageName = "tpl_boss_transparent"
            let bossTitles = ["老板气质检测报告", "领导感自动识别中", "开会人设鉴定卡", "气场管理观察报告", "朋友局老板样本", "总结型人格分析", "画饼能力检测卡", "气质压迫感报告", "群聊管理者说明书", "疑似老板行为记录", "发言含金量分析", "会议感溢出警报"]
            let bossSubtitles = ["一句话不长，但很像在布置任务", "不是想管事，是气质已经先到了", "坐在那里不说话，也像要开会", "朋友局里最像会总结的人出现了", "你不一定是老板，但很会像老板", "这气场不是装的，是日常泄露", "讲话自带重点，听完想记笔记", "别人聊天，你像在主持会议", "表情不多，但压迫感很稳定", "你一开口，气氛自动进入议程"]
            let bossEvidence = [“喜欢把事情分成第一、第二、第三点”, “说话不一定多，但每句都像最终意见”, “朋友问去哪吃，你能顺手做出决策表”, “表情稳定，像在听汇报”, “别人还在聊天，你已经开始总结”, “遇到问题第一反应不是慌，是安排”, “语气很平静，但别人会不自觉听你的”, “一句”这样吧”，直接进入管理模式”, “朋友圈不一定发，但一发就像公告”, “对混乱场面有天然整理欲”, “不说废话，但会让别人觉得自己说了废话”, “很少激动，主打一个稳住局面”, “能把小事讲得像项目复盘”, “对时间和流程有莫名执念”, “看似随和，实际很有主意”, “别人还没想明白，你已经开始收尾”, “不是爱管人，是你太像能负责的人”, “聚会里总有人问你意见，这就很说明问题”, “开口之前气氛轻松，开口之后大家开始认真”, “你不是老板，但已经掌握了老板语气”]
            let bossLevels = [“轻度领导感”, “朋友局主理人”, “会议感溢出”, “气场稳定型”, “总结型人格”, “画饼预备役”, “决策担当”, “疑似老板气质”]
            let bossFinals = [“建议少说”我简单讲两句”，因为听起来一点都不简单”, “你不是非要当老板，是气质已经替你报名了”, “朋友局里有你，流程感会突然变强”, “别人是来玩的，你像是来控场的”, “你适合负责结论，不适合装路人”, “这份老板感不用刻意，已经自然溢出了”, “最终结论：你不一定想管事，但大家容易默认你能管”, “建议收一收总结欲，不然朋友会以为在开周会”, “你的气场基础，当普通朋友就不基础”, “这波不是装成熟，是确实有点稳”]

            title = bossTitles.randomElement() ?? “”
            subtitle = bossSubtitles.randomElement() ?? “”
            resultLevel = bossLevels.randomElement() ?? “”
            finalComment = tonePrefix + (bossFinals.randomElement() ?? “”)
            stats = [StatItem(name: “控场能力”, value: Int.random(in: 60...100)), StatItem(name: “总结欲”, value: Int.random(in: 60...100)), StatItem(name: “气场指数”, value: Int.random(in: 60...100))]
            evidenceList = Array(bossEvidence.shuffled().prefix(3))
            
        case "group_judge":
            templateType = "verdict"
            imageName = "icon_judge"
            let defendantInput = inputs["defendant"] ?? "某人"
            let judgeTitles = ["群聊临时判决书", "朋友局小法庭", "今日群聊审判", "奶茶责任认定", "已读不回调查报告", "饭局责任裁定", "群友联合观察记录", "轻量级判官上线", "本群今日裁定", "气氛组责任书", "临时开庭通知", "群聊行为鉴定"]
            let judgeCaseSummaries = ["经群友观察，被告在关键时刻出现了稳定掉线现象", "本案证据不多，但聊天记录已经说明了一些问题", "被告行为看似无意，实际对群聊气氛造成轻微影响", "群友一致认为，此事不大，但必须有个说法", "被告多次试图保持沉默，但沉默本身也成为了证据", "本次事件属于典型朋友局小型争议，适合轻判不适合翻脸", "经简单复盘，被告确实存在一点点可疑操作", "案情并不复杂，复杂的是被告还想解释", "群聊现场气氛稳定，但责任归属已经逐渐清晰", "本案核心不是严重，而是有点太好笑了", "被告虽然没有造成实际损失，但节目效果已经产生", "群友认为可以原谅，但不能当作没发生", "该行为属于轻微整活事故，建议现场处理", "从聊天记录看，被告的操作存在一点点离谱成分", "本次判决只为活跃气氛，不影响朋友关系"]
            let judgeCrimeTexts = ["已读不回", "关键时刻消失", "迟到但很淡定", "只发表情不说话", "装作没看见", "饭点突然失联", "嘴上说马上到", "说随便但很挑", "气氛到了人没到", "重要消息选择性失联"]
            let judgeShortVerdicts = ["请喝奶茶", "发个表情包", "下次请客", "当气氛组", "公开解释", "主动认领", "补发消息", "发句道歉", "负责点单", "接受调侃", "请大家吃饭", "今晚别潜水"]
            let judgeFinals = ["本次判决主打轻松处理，别急着上诉", "建议被告主动认领，效果会比解释更好", "群友不是要追责，主要是想看你怎么圆", "这件事不严重，但确实值得被截图纪念", "本庭认为：朋友局里，态度比理由重要", "解释可以有，但奶茶也可以有", "别紧张，本次判决不影响你在群里的长期形象", "建议下次出现得早一点，别让证据链太完整", "本案到此为止，除非群友继续起哄", "最终建议：少潜水，多冒泡，群聊更美好"]

            title = judgeTitles.randomElement() ?? ""
            subtitle = "被告人：\(defendantInput.isEmpty ? "某神秘群友" : defendantInput)"
            
            var crimes: [String] = []
            if multiSelect.isEmpty {
                crimes = Array(judgeCrimeTexts.shuffled().prefix(3))
            } else {
                crimes = multiSelect
            }
            evidenceList = [judgeCaseSummaries.randomElement() ?? ""]
            evidenceList.append(contentsOf: crimes.map { "主要行为：\($0)" })

            resultLevel = String((judgeShortVerdicts.randomElement() ?? "").prefix(10))
            finalComment = tonePrefix + (judgeFinals.randomElement() ?? "")
            
        case "friend_vote":
            templateType = "rank"
            imageName = "icon_vote"
            let topic = inputs["topic"] ?? "神秘榜单"
            let voteTitles = ["朋友局临时排行榜", "今日群聊投票结果", "好友观察榜单", "谁最像榜单公示", "群友印象排行", "本局投票已出炉", "友情观察结果", "离谱但合理榜", "群聊民意调查", "朋友局结果公示", "今日整活排行", "群友一致认定"]
            let voteReasons = ["平时不显山不露水，关键时刻很有存在感", "这个排名有点离谱，但大家好像都能理解", "票数不是最高调的，但理由很充分", "看似无辜，实际很符合主题", "群友投票主打一个凭感觉，但感觉很准", "这位选手属于越想越合理的类型", "没有特别努力，但气质已经赢了", "大家嘴上没说，心里可能早就这么想了", "不是强行安排，是确实有点像", "这个名字一出现，榜单突然就合理了", "属于不解释也能懂的程度", "这个位置很适合，甚至有点量身定制", "票数说明不了一切，但能说明群友很会看人", "排名可能有争议，但节目效果没有争议", "这位朋友的标签感太强，想不入榜都难", "看起来像玩笑，实际上带点真实", "不是针对谁，只是太符合题目", "群友的眼光不能说全对，但这次挺准", "这个结果一出来，群里应该会安静两秒", "建议本人不要急着反驳，越反驳越像"]
            let voteFinals = ["本榜单仅供整活，认真你就输了", "排名不代表真相，但代表群友今天的心情", "允许本人上诉，但不保证有人听", "榜单可以重开，但笑点已经成立", "本次结果主打一个热闹，不负责后续解释", "群友投票有偏差，但很有节目效果", "如果不服，可以发起下一轮投票", "友情提示：榜单越离谱，群聊越热闹", "本局到此结束，欢迎下次继续互相伤害", "最终解释权归群友和截图所有"]
            let rankLabels = ["TOP 1 断层领先", "TOP 2 稳定上榜", "TOP 3 压线入围", "隐藏选手", "气氛担当", "争议候选"]

            title = voteTitles.randomElement() ?? ""
            subtitle = "评选主题：\(topic)"
            
            var shuffledParticipants = participants.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.shuffled()
            if shuffledParticipants.isEmpty { shuffledParticipants = ["路人甲", "路人乙", "路人丙"] }

            for (index, person) in shuffledParticipants.prefix(3).enumerated() {
                let rankStr = index < 3 ? rankLabels[index] : (rankLabels.randomElement() ?? "")
                let reason = voteReasons.randomElement() ?? ""
                evidenceList.append("\(person) (\(rankStr)) - \(reason)")
            }

            resultLevel = "年度最具争议榜单"
            finalComment = tonePrefix + (voteFinals.randomElement() ?? "")
            
        case "truth_dare":
            templateType = "task"
            imageName = "icon_truth_dare"
            let mode = singleSelect1
            let truthQuestions = ["最近一次偷偷羡慕别人，是因为什么？", "如果现在可以立刻放假一天，你最想去哪里？", "你最近最想收到的一句话是什么？", "有没有一个人，你其实很想联系但一直没联系？", "你最容易被哪种细节打动？", "最近有没有一件事让你觉得自己挺不容易的？", "你最想改掉但一直没改掉的小习惯是什么？", "如果朋友现在请你吃饭，你最想吃什么？", "你最近一次心情变好，是因为什么？", "你觉得自己最像哪种小动物？", "有没有一句话你嘴上不说，但心里很在意？", "你最想对未来一周的自己说什么？", "你最近最需要的情绪价值是什么？", "你最喜欢朋友怎么安慰你？", "如果今晚不用考虑任何事，你会怎么安排？"]
            let dareTasks = ["给最近聊天的朋友发一句：今天辛苦了", "在群里发一个你最近常用的表情包", "拍一张现在身边的小物件，发给朋友", "给一个朋友发一句：我刚刚突然想起你", "发一条只保留 10 分钟的生活动态", "给朋友推荐一首你最近常听的歌", "在群里发一句：今天谁请我喝奶茶", "给最近帮过你的人发一句谢谢", "把今天的心情用三个词发出来", "找一张你觉得好笑的图发给朋友", "给一个朋友发一句：下次一起吃饭", "把今天最想吃的东西发到群里", "用一句话描述今天的精神状态", "发一个表情包，让大家猜你的心情", "给自己发一条备忘录：明天别忘了休息"]
            let truthDareLevels = ["轻松局", "有点心跳", "朋友局刚好", "轻微社死", "气氛担当", "勇敢一次", "适合热场", "别想太多"]
            let failurePunishments = ["下一轮必须先选", "发一个表情包认领失败", "给大家补一句解释", "下一题不能跳过", "负责带动下一轮气氛", "请朋友帮你选下一题", "用一句话总结失败感想", "给自己一个台阶：我只是太谨慎了"]

            let isTruth = mode == "真心话" || (mode == "随机" && Bool.random())
            title = isTruth ? "真心话时间" : "大冒险时间"
            subtitle = isTruth ? "坦诚相待局" : "行动力测试"

            let task = isTruth ? (truthQuestions.randomElement() ?? "") : (dareTasks.randomElement() ?? "")

            evidenceList = [
                "目标玩家：\(nickname)",
                "难度标签：\(truthDareLevels.randomElement() ?? "")",
                "执行内容：\(task)",
                "失败惩罚：\(failurePunishments.randomElement() ?? "")"
            ]

            resultLevel = isTruth ? "勇敢说真话" : "果断去执行"
            finalComment = tonePrefix + "大家都在看着呢，别想轻易蒙混过关"
            
        default:
            templateType = "diagnostic"
            imageName = "icon_persona"
            let personaTitles = ["今日人设卡", "今日状态说明书", "今日精神面貌", "今日社交电量", "今日生活模式", "今日气质检测", "今日状态条", "今日角色加载中", "今日人类观察报告", "今日情绪说明", "今日生存模式", "今日整活身份"]
            let personaLevels = ["低电量但能用", "表面冷静", "轻微发疯", "稳定摸鱼", "情绪价值不足", "活人感恢复中", "从容是假的", "连滚带爬但完成", "看似没事", "今天先这样吧"]
            let personaEvidence = ["早上看起来还行，中午开始进入省电模式", "嘴上说没事，表情已经提前下班", "今天的状态主打一个能撑就撑", "社交电量不高，但礼貌系统还在运行", "看似从容，实际后台开了很多程序", "情绪没有崩，只是暂时不想加载", "今天适合少说话，多喝水", "脑子在线，但响应速度略有延迟", "表面平静，内心已经打开勿扰模式", "不是不努力，是电量分配比较谨慎", "今天不适合复杂沟通，适合简单活着", "工作/学习状态：能做，但不要催", "外表是人，内心是加载中的小图标", "今天的活人感有，但不多", "建议降低期待，减少不必要输出", "不是摆烂，是战略性节能", "可以交流，但请先预约精神状态", "今日关键词：慢一点也可以", "看起来没醒，实际已经很努力了", "今天的你，能出现就已经不错了"]
            let personaFinals = ["今天不用太完美，能稳定运行就算赢", "建议给自己一点情绪价值，别全给别人", "这状态不算差，只是需要少一点打扰", "今日适合轻量生活，不适合硬扛全场", "你不是不行，你只是需要缓冲", "今天先把自己照顾好，其他事慢慢来", "别急着证明什么，能完成基础任务就很好", "当前状态建议：少内耗，多喝水", "今天不必强行满格，半格也能过", "最终结论：你已经很努力了，别再压榨自己"]

            title = personaTitles.randomElement() ?? ""
            subtitle = "\(nickname) 的今日诊断"
            resultLevel = personaLevels.randomElement() ?? ""
            finalComment = tonePrefix + (personaFinals.randomElement() ?? "")
            stats = [StatItem(name: "社交电量", value: Int.random(in: 10...50)), StatItem(name: "活人感", value: Int.random(in: 10...80)), StatItem(name: "伪装从容", value: Int.random(in: 60...100))]
            evidenceList = Array(personaEvidence.shuffled().prefix(3))
        }
        
        if let customQuote = inputs["customQuote"], !customQuote.trimmingCharacters(in: .whitespaces).isEmpty {
            quote = customQuote
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
            styleTone: toneInput,
            participants: participants,
            templateType: templateType,
            createdAt: date
        )
    }
}
