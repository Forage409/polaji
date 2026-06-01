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

struct TemplateResultConfig: Codable, Equatable {
    static let currentVersion = 3

    var version: Int = currentVersion
    var layout: ResultLayoutPreset = .socialPoster
    var defaultThemePackId: String = "dreamy_persona"
    var allowedThemePackIds: [String] = ["dreamy_persona"]
    var defaultHeroStickerId: String? = nil
    var defaultDecorationStickerIds: [String] = []
    var moduleOrder: [ResultModuleKind] = ResultModuleKind.allCases
    var hiddenModules: [ResultModuleKind] = [.fields]
    var copyLibrary: TemplateCopyLibrary? = nil

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
            copyLibrary: copyLibrary?.normalized()
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
            seed: seed
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
            seed: 88
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
        seed: Int
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
        config: TemplateResultConfig
    ) -> ResultCardDocument {
        let cfg = config.normalized()
        let pack = ResultThemePack.find(cfg.defaultThemePackId)
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
            heroStickerId: cfg.defaultHeroStickerId ?? pack.heroStickers.randomElement(),
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

    private static func pickOne(_ values: [String], seed: Int) -> String {
        guard !values.isEmpty else { return "" }
        return values[abs(seed) % values.count]
    }

    private static func pick(_ values: [String], count: Int, seed: Int) -> [String] {
        guard !values.isEmpty else { return [] }
        return (0..<min(count, values.count)).map { values[(abs(seed) + $0) % values.count] }
    }
}
