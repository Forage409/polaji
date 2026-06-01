import Foundation

enum ResultLayoutPreset: String, Codable, CaseIterable, Identifiable {
    case report
    case ranking
    case verdict
    case challenge
    case socialPoster

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .report: return "报告卡"
        case .ranking: return "排行榜"
        case .verdict: return "判决书"
        case .challenge: return "挑战任务"
        case .socialPoster: return "社交海报"
        }
    }
}

enum ResultModuleKind: String, Codable, CaseIterable, Identifiable {
    case header
    case hero
    case stats
    case fields
    case evidence
    case result
    case quote
    case footer

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .header: return "标题"
        case .hero: return "主贴纸"
        case .stats: return "数据指标"
        case .fields: return "填写结果"
        case .evidence: return "内容列表"
        case .result: return "最终结论"
        case .quote: return "趣味文案"
        case .footer: return "底部署名"
        }
    }

    var isRequired: Bool {
        self == .header || self == .footer
    }
}

struct ResultFieldValue: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var label: String
    var value: String
}

struct TemplateCopyLibrary: Codable, Equatable {
    var stats: [String]
    var evidencePool: [String]
    var finalPool: [String]
    var levels: [String]

    func normalized() -> TemplateCopyLibrary {
        TemplateCopyLibrary(
            stats: Array(stats.map { String($0.prefix(12)) }.filter { !$0.isEmpty }.prefix(4)),
            evidencePool: Array(evidencePool.map { String($0.prefix(80)) }.filter { !$0.isEmpty }.prefix(8)),
            finalPool: Array(finalPool.map { String($0.prefix(100)) }.filter { !$0.isEmpty }.prefix(6)),
            levels: Array(levels.map { String($0.prefix(24)) }.filter { !$0.isEmpty }.prefix(6))
        )
    }

    var isUsable: Bool {
        let copy = normalized()
        return copy.stats.count >= 2 && copy.evidencePool.count >= 3 && copy.finalPool.count >= 2 && copy.levels.count >= 2
    }
}

struct TemplateOutcomeStat: Codable, Equatable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var value: Int

    func normalized() -> TemplateOutcomeStat {
        TemplateOutcomeStat(
            id: id,
            name: String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(12)),
            value: min(100, max(0, value))
        )
    }
}

struct TemplateOutcome: Codable, Equatable, Identifiable {
    var id: String = UUID().uuidString
    var title: String
    var subtitle: String
    var resultLevel: String
    var quote: String
    var finalComment: String
    var evidencePool: [String]
    var stats: [TemplateOutcomeStat]
    var themePackId: String? = nil
    var heroStickerId: String? = nil

    func normalized() -> TemplateOutcome {
        let knownThemeIds = Set(ResultThemePack.all.map(\.id))
        let safeTheme = themePackId.flatMap { knownThemeIds.contains($0) ? $0 : nil }
        let safeHero = safeTheme.flatMap { themeId in
            let pack = ResultThemePack.find(themeId)
            return pack.heroStickers.contains(heroStickerId ?? "") ? heroStickerId : pack.heroStickers.first
        }
        return TemplateOutcome(
            id: id.isEmpty ? UUID().uuidString : id,
            title: String(title.trimmingCharacters(in: .whitespacesAndNewlines).prefix(18)),
            subtitle: String(subtitle.trimmingCharacters(in: .whitespacesAndNewlines).prefix(30)),
            resultLevel: String(resultLevel.trimmingCharacters(in: .whitespacesAndNewlines).prefix(16)),
            quote: String(quote.trimmingCharacters(in: .whitespacesAndNewlines).prefix(36)),
            finalComment: String(finalComment.trimmingCharacters(in: .whitespacesAndNewlines).prefix(50)),
            evidencePool: Array(evidencePool.map {
                String($0.trimmingCharacters(in: .whitespacesAndNewlines).prefix(28))
            }.filter { !$0.isEmpty }.prefix(6)),
            stats: Array(stats.map { $0.normalized() }.filter { !$0.name.isEmpty }.prefix(3)),
            themePackId: safeTheme,
            heroStickerId: safeHero
        )
    }

    var isUsable: Bool {
        let outcome = normalized()
        return !outcome.title.isEmpty &&
            !outcome.subtitle.isEmpty &&
            !outcome.resultLevel.isEmpty &&
            !outcome.quote.isEmpty &&
            !outcome.finalComment.isEmpty &&
            outcome.evidencePool.count >= 3 &&
            outcome.stats.count >= 2
    }
}

struct OptionOutcomeWeight: Codable, Equatable, Identifiable {
    var id: String = UUID().uuidString
    var fieldId: String
    var option: String
    var scores: [String: Int]

    func normalized(validOutcomeIds: Set<String>) -> OptionOutcomeWeight {
        OptionOutcomeWeight(
            id: id.isEmpty ? UUID().uuidString : id,
            fieldId: fieldId,
            option: String(option.trimmingCharacters(in: .whitespacesAndNewlines).prefix(16)),
            scores: scores.reduce(into: [:]) { result, item in
                guard validOutcomeIds.contains(item.key) else { return }
                result[item.key] = min(10, max(0, item.value))
            }
        )
    }
}

struct TemplateOutcomePackage: Codable, Equatable {
    var outcomes: [TemplateOutcome]
    var weights: [OptionOutcomeWeight]

    func normalized() -> TemplateOutcomePackage {
        let safeOutcomes = Array(outcomes.map { $0.normalized() }.filter(\.isUsable).prefix(8))
        let validOutcomeIds = Set(safeOutcomes.map(\.id))
        return TemplateOutcomePackage(
            outcomes: safeOutcomes,
            weights: Array(weights.map { $0.normalized(validOutcomeIds: validOutcomeIds) }
                .filter { !$0.fieldId.isEmpty && !$0.option.isEmpty }
                .prefix(64))
        )
    }

    var isUsable: Bool {
        let package = normalized()
        return package.outcomes.count >= 4
    }

    static func starter(fields: [TemplateField]) -> TemplateOutcomePackage {
        let outcomes = [
            TemplateOutcome(title: "气氛中心", subtitle: "你一出现，群聊就自动开场", resultLevel: "朋友圈主角", quote: "平时看着低调，关键时刻从不缺节目效果。", finalComment: "你的回答已经暴露了隐藏属性：表面随和，实际自带气氛加成。", evidencePool: ["出场自带话题，不需要额外铺垫", "看似随手一选，其实很会拿捏气氛", "朋友局里总能贡献意外名场面"], stats: [TemplateOutcomeStat(name: "话题浓度", value: 92), TemplateOutcomeStat(name: "分享欲", value: 88)]),
            TemplateOutcome(title: "稳中带梗", subtitle: "不抢镜，但每次都能精准补刀", resultLevel: "冷静观察员", quote: "不必频繁发言，开口就是重点。", finalComment: "你属于慢热型整活选手，平时安静，真正出手时往往最有效。", evidencePool: ["习惯先观察，再给出关键一击", "不靠音量取胜，靠的是时机", "别人还在铺垫，你已经看穿结局"], stats: [TemplateOutcomeStat(name: "观察指数", value: 90), TemplateOutcomeStat(name: "精准度", value: 86)]),
            TemplateOutcome(title: "反差选手", subtitle: "越认真回答，越容易制造惊喜", resultLevel: "隐藏彩蛋", quote: "看起来很正常，细看每一项都不太简单。", finalComment: "你的答案组合充满反差感，属于截图发出去最容易引发讨论的类型。", evidencePool: ["答案组合看似合理，拼起来却很有戏", "越往后看，反差越明显", "属于需要二刷才能看懂的隐藏角色"], stats: [TemplateOutcomeStat(name: "反差指数", value: 94), TemplateOutcomeStat(name: "回味程度", value: 84)]),
            TemplateOutcome(title: "随缘天才", subtitle: "没有刻意安排，但结果总是很有效果", resultLevel: "随机事件制造者", quote: "你甚至没想整活，整活却会主动找到你。", finalComment: "你的路线无法简单归类，最大的特点就是每次都能自然地产生新剧情。", evidencePool: ["选择没有固定套路，胜在自然", "擅长在普通场景里触发随机事件", "朋友很难预测你的下一步操作"], stats: [TemplateOutcomeStat(name: "随机指数", value: 89), TemplateOutcomeStat(name: "剧情浓度", value: 91)])
        ]
        let weights = fields.flatMap { field in
            guard field.type == .singleSelect || field.type == .multiSelect else { return [] }
            return field.options.enumerated().map { optionIndex, option in
                OptionOutcomeWeight(
                    fieldId: field.id,
                    option: option,
                    scores: [outcomes[optionIndex % outcomes.count].id: 6]
                )
            }
        }
        return TemplateOutcomePackage(outcomes: outcomes, weights: weights)
    }
}

struct TemplateResultConfig: Codable, Equatable {
    static let currentVersion = 4

    var version: Int = currentVersion
    var layout: ResultLayoutPreset = .socialPoster
    var defaultThemePackId: String = "dreamy_persona"
    var allowedThemePackIds: [String] = ["dreamy_persona"]
    var defaultHeroStickerId: String? = nil
    var defaultDecorationStickerIds: [String] = []
    var moduleOrder: [ResultModuleKind] = ResultModuleKind.allCases
    var hiddenModules: [ResultModuleKind] = [.fields]
    var copyLibrary: TemplateCopyLibrary? = nil
    var outcomePackage: TemplateOutcomePackage? = nil

    static let `default` = TemplateResultConfig()

    func normalized() -> TemplateResultConfig {
        let knownThemeIds = Set(ResultThemePack.all.map(\.id))
        let fallbackTheme = knownThemeIds.contains(defaultThemePackId) ? defaultThemePackId : "dreamy_persona"
        var allowed = allowedThemePackIds.filter { knownThemeIds.contains($0) }
        if !allowed.contains(fallbackTheme) {
            allowed.insert(fallbackTheme, at: 0)
        }

        var ordered: [ResultModuleKind] = []
        for module in moduleOrder + ResultModuleKind.allCases where !ordered.contains(module) {
            ordered.append(module)
        }

        var hidden = hiddenModules.filter { !$0.isRequired }
        if version < Self.currentVersion, !hidden.contains(.fields) {
            hidden.append(.fields)
        }
        let visibleContent = ordered.filter { !$0.isRequired && !hidden.contains($0) }
        if visibleContent.isEmpty {
            hidden.removeAll { $0 == .fields }
        }

        let theme = ResultThemePack.find(fallbackTheme)
        let hero = theme.heroStickers.contains(defaultHeroStickerId ?? "") ? defaultHeroStickerId : theme.heroStickers.first
        let decorations = Array(defaultDecorationStickerIds.filter { theme.decorationStickers.contains($0) }.prefix(3))

        return TemplateResultConfig(
            version: Self.currentVersion,
            layout: layout,
            defaultThemePackId: fallbackTheme,
            allowedThemePackIds: allowed,
            defaultHeroStickerId: hero,
            defaultDecorationStickerIds: decorations,
            moduleOrder: ordered,
            hiddenModules: hidden,
            copyLibrary: copyLibrary?.normalized(),
            outcomePackage: outcomePackage?.normalized()
        )
    }

    func toJSONString() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        guard let data = try? encoder.encode(normalized()),
              let raw = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return raw
    }

    static func parse(_ raw: String?, legacyStyle: TemplateCardStyle? = nil) -> TemplateResultConfig {
        guard let raw, !raw.isEmpty,
              let data = raw.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(TemplateResultConfig.self, from: data) else {
            return legacyDefault(for: legacyStyle)
        }
        return decoded.normalized()
    }

    static func official(for templateId: String) -> TemplateResultConfig {
        switch templateId {
        case "group_judge":
            return make(layout: .verdict, theme: "courtroom_red")
        case "friend_vote":
            return make(layout: .ranking, theme: "pop_party")
        case "truth_dare":
            return make(layout: .challenge, theme: "pop_party")
        case "rich_card":
            return make(layout: .report, theme: "fortune_gold")
        case "single_card":
            return make(layout: .socialPoster, theme: "pink_crush")
        case "stay_up":
            return make(layout: .report, theme: "midnight_mode")
        case "boss_card", "office_survival":
            return make(layout: templateId == "boss_card" ? .report : .socialPoster, theme: "office_satire")
        default:
            return make(layout: .report, theme: "dreamy_persona")
        }
    }

    private static func make(layout: ResultLayoutPreset, theme: String) -> TemplateResultConfig {
        let pack = ResultThemePack.find(theme)
        return TemplateResultConfig(
            layout: layout,
            defaultThemePackId: theme,
            allowedThemePackIds: ResultThemePack.all.map(\.id),
            defaultHeroStickerId: pack.heroStickers.first,
            defaultDecorationStickerIds: Array(pack.decorationStickers.prefix(2))
        ).normalized()
    }

    private static func legacyDefault(for style: TemplateCardStyle?) -> TemplateResultConfig {
        let theme: String
        switch style?.background {
        case .creamYellow: theme = "fortune_gold"
        case .mintGreen: theme = "campus_fun"
        case .sakuraPink: theme = "pink_crush"
        case .midnightBlue: theme = "midnight_mode"
        default: theme = "dreamy_persona"
        }
        return make(layout: .socialPoster, theme: theme)
    }
}

struct ResultCardDocument: Identifiable {
    let id: String
    let templateId: String
    var layout: ResultLayoutPreset
    var title: String
    var subtitle: String
    var fields: [ResultFieldValue]
    var stats: [StatItem]
    var evidence: [String]
    var resultLevel: String
    var quote: String
    var finalComment: String
    var createdAt: String
    var themePackId: String
    var backgroundId: String
    var heroStickerId: String?
    var decorationStickerIds: [String]
    var moduleOrder: [ResultModuleKind]
    var hiddenModules: Set<ResultModuleKind>

    var themePack: ResultThemePack {
        ResultThemePack.find(themePackId)
    }

    mutating func applyTheme(_ id: String, randomize: Bool = false) {
        let pack = ResultThemePack.find(id)
        themePackId = pack.id
        backgroundId = randomize ? (pack.backgrounds.randomElement() ?? pack.backgrounds[0]) : pack.backgrounds[0]
        heroStickerId = randomize ? pack.heroStickers.randomElement() : pack.heroStickers.first
        decorationStickerIds = Array((randomize ? pack.decorationStickers.shuffled() : pack.decorationStickers).prefix(2))
    }

    mutating func randomizeThemeAssets() {
        applyTheme(themePackId, randomize: true)
    }

    static func fromGeneratedCard(_ card: GeneratedCard, config: TemplateResultConfig) -> ResultCardDocument {
        make(
            id: card.id,
            templateId: card.templateId,
            title: card.title,
            subtitle: card.subtitle,
            fields: [],
            stats: card.stats,
            evidence: card.evidenceList,
            resultLevel: card.resultLevel,
            quote: card.quote,
            finalComment: card.finalComment,
            createdAt: card.createdAt,
            config: config
        )
    }

    static func fromCustomTemplate(_ template: Template, inputs: [String: String]) -> ResultCardDocument {
        let fields = (template.customFields ?? []).map {
            ResultFieldValue(label: $0.label, value: inputs[$0.label] ?? "")
        }
        let seed = stableSeed(templateId: template.id, fields: fields)
        return makeCustom(
            id: UUID().uuidString,
            templateId: template.id,
            title: template.name,
            subtitle: "by \(UserProfileStore.shared.nickname)",
            fields: fields,
            createdAt: LocalTimeFormatter.now(),
            config: template.resultConfig,
            preview: false,
            seed: seed,
            fieldsDefinition: template.customFields ?? [],
            inputs: inputs
        )
    }

    static func preview(config: TemplateResultConfig, title: String, fields: [TemplateField]) -> ResultCardDocument {
        let previewFields = fields.map {
            ResultFieldValue(label: $0.label.isEmpty ? "未命名" : $0.label, value: sampleValue(for: $0))
        }
        return makeCustom(
            id: "preview",
            templateId: "preview",
            title: title.isEmpty ? "玩法标题" : title,
            subtitle: "潮流贴纸结果卡",
            fields: previewFields.isEmpty ? [ResultFieldValue(label: "昵称", value: "小幽灵")] : previewFields,
            createdAt: "预览",
            config: config,
            preview: true,
            seed: 88,
            fieldsDefinition: fields,
            inputs: Dictionary(uniqueKeysWithValues: previewFields.map { ($0.label, $0.value) })
        )
    }

    private static func makeCustom(
        id: String,
        templateId: String,
        title: String,
        subtitle: String,
        fields: [ResultFieldValue],
        createdAt: String,
        config: TemplateResultConfig,
        preview: Bool,
        seed: Int,
        fieldsDefinition: [TemplateField],
        inputs: [String: String]
    ) -> ResultCardDocument {
        let visibleFields = fields.filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let evidenceTemplates: [(ResultFieldValue) -> String] = [
            { "「\($0.label)」已经暴露关键倾向：\($0.value)" },
            { "从「\($0.label)」来看，现场气氛正在向 \($0.value) 偏移" },
            { "在「\($0.label)」这一项选择 \($0.value)，节目效果已经成立" }
        ]
        let evidence = Array(visibleFields.prefix(3).enumerated()).map { index, field in
            evidenceTemplates[index % evidenceTemplates.count](field)
        }
        let library = config.normalized().copyLibrary
        let libraryEvidence = pick(library?.evidencePool ?? [], count: 3, seed: seed)
        let score = preview ? 88 : 76 + seed % 23
        let atmosphereScore = preview ? 96 : 74 + (seed / 7) % 25
        let resultLevels = ["自带话题体质", "朋友圈主角", "现场气氛担当", "整活潜力拉满"]
        let quotes = ["这波不是普通发挥，是可以直接截图发群的程度。", "结论已经很明显：今天的节目效果由你负责。", "看似随手一填，实际已经把气氛拿捏住了。", "建议保留证据，群友迟早会回来复盘。"]
        if let outcome = selectOutcome(
            package: config.normalized().outcomePackage,
            fields: fieldsDefinition,
            inputs: inputs,
            seed: seed,
            preview: preview
        ) {
            return make(
                id: id,
                templateId: templateId,
                title: outcome.title,
                subtitle: outcome.subtitle,
                fields: fields,
                stats: outcome.stats.map { StatItem(name: $0.name, value: $0.value) },
                evidence: pick(outcome.evidencePool, count: 3, seed: seed),
                resultLevel: outcome.resultLevel,
                quote: outcome.quote,
                finalComment: outcome.finalComment,
                createdAt: createdAt,
                config: config,
                themePackId: outcome.themePackId,
                heroStickerId: outcome.heroStickerId
            )
        }
        return make(
            id: id,
            templateId: templateId,
            title: title,
            subtitle: subtitle,
            fields: fields,
            stats: [
                StatItem(name: library?.stats.first ?? "整活吸引力", value: score),
                StatItem(name: library?.stats.dropFirst().first ?? "传播潜力", value: atmosphereScore)
            ],
            evidence: libraryEvidence.isEmpty ? evidence : libraryEvidence,
            resultLevel: preview ? "朋友圈主角" : pickOne(library?.levels ?? resultLevels, seed: seed),
            quote: preview ? "这波不是普通发挥，是可以直接截图发群的程度。" : quotes[(seed / 11) % quotes.count],
            finalComment: pickOne(library?.finalPool ?? ["你的专属结果已经生成，建议截图保存，等待群友认领。"], seed: seed / 13),
            createdAt: createdAt,
            config: config
        )
    }

    private static func make(
        id: String,
        templateId: String,
        title: String,
        subtitle: String,
        fields: [ResultFieldValue],
        stats: [StatItem],
        evidence: [String],
        resultLevel: String,
        quote: String,
        finalComment: String,
        createdAt: String,
        config: TemplateResultConfig,
        themePackId: String? = nil,
        heroStickerId: String? = nil
    ) -> ResultCardDocument {
        let cfg = config.normalized()
        let pack = ResultThemePack.find(themePackId ?? cfg.defaultThemePackId)
        return ResultCardDocument(
            id: id,
            templateId: templateId,
            layout: cfg.layout,
            title: title,
            subtitle: subtitle,
            fields: fields,
            stats: stats,
            evidence: evidence,
            resultLevel: resultLevel,
            quote: quote,
            finalComment: finalComment,
            createdAt: createdAt,
            themePackId: pack.id,
            backgroundId: pack.backgrounds.randomElement() ?? pack.backgrounds[0],
            heroStickerId: heroStickerId ?? cfg.defaultHeroStickerId ?? pack.heroStickers.randomElement(),
            decorationStickerIds: Array((cfg.defaultDecorationStickerIds.isEmpty ? pack.decorationStickers.shuffled() : cfg.defaultDecorationStickerIds).prefix(3)),
            moduleOrder: cfg.moduleOrder,
            hiddenModules: Set(cfg.hiddenModules)
        )
    }

    private static func sampleValue(for field: TemplateField) -> String {
        switch field.type {
        case .text: return "示例内容"
        case .number: return "88"
        case .singleSelect: return field.options.first ?? "选项 A"
        case .multiSelect: return field.options.prefix(2).joined(separator: "、")
        case .participants: return "小明、小美、阿杰"
        }
    }

    private static func stableSeed(templateId: String, fields: [ResultFieldValue]) -> Int {
        let source = ([templateId] + fields.flatMap { [$0.label, $0.value] }).joined(separator: "|")
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in source.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return Int(hash % 10_000)
    }

    private static func selectOutcome(
        package: TemplateOutcomePackage?,
        fields: [TemplateField],
        inputs: [String: String],
        seed: Int,
        preview: Bool
    ) -> TemplateOutcome? {
        guard let package, package.isUsable else { return nil }
        let normalized = package.normalized()
        if preview { return normalized.outcomes.first }

        var scores = Dictionary(uniqueKeysWithValues: normalized.outcomes.map { ($0.id, 0) })
        for weight in normalized.weights {
            guard let field = fields.first(where: { $0.id == weight.fieldId }),
                  let answer = inputs[field.label] else { continue }
            let selected = Set(answer.split(separator: "、").map(String.init))
            guard selected.contains(weight.option) else { continue }
            for (outcomeId, value) in weight.scores {
                scores[outcomeId, default: 0] += value
            }
        }

        let highestScore = scores.values.max() ?? 0
        let tied = normalized.outcomes.filter { scores[$0.id, default: 0] == highestScore }
        guard !tied.isEmpty else { return normalized.outcomes.first }
        return tied[abs(seed) % tied.count]
    }

    private static func pickOne(_ values: [String], seed: Int) -> String {
        guard !values.isEmpty else { return "" }
        return values[abs(seed) % values.count]
    }

    private static func pick(_ values: [String], count: Int, seed: Int) -> [String] {
        guard !values.isEmpty else { return [] }
        return (0..<min(count, values.count)).map { values[(abs(seed) + $0) % values.count] }
    }
}
