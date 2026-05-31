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

struct TemplateResultConfig: Codable, Equatable {
    static let currentVersion = 1

    var version: Int = currentVersion
    var layout: ResultLayoutPreset = .socialPoster
    var defaultThemePackId: String = "dreamy_persona"
    var allowedThemePackIds: [String] = ["dreamy_persona"]
    var defaultHeroStickerId: String? = nil
    var defaultDecorationStickerIds: [String] = []
    var moduleOrder: [ResultModuleKind] = ResultModuleKind.allCases
    var hiddenModules: [ResultModuleKind] = []

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
            hiddenModules: hidden
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
        return makeCustom(
            id: UUID().uuidString,
            templateId: template.id,
            title: template.name,
            subtitle: "by \(UserProfileStore.shared.nickname)",
            fields: fields,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            config: template.resultConfig,
            preview: false
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
            preview: true
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
        preview: Bool
    ) -> ResultCardDocument {
        let evidence = Array(fields.prefix(3).map {
            "\($0.label)：\($0.value.isEmpty ? "待填写" : $0.value)"
        })
        let score = preview ? 88 : Int.random(in: 72...98)
        return make(
            id: id,
            templateId: templateId,
            title: title,
            subtitle: subtitle,
            fields: fields,
            stats: [
                StatItem(name: "整活指数", value: score),
                StatItem(name: "氛围适配", value: preview ? 96 : Int.random(in: 70...99))
            ],
            evidence: evidence,
            resultLevel: preview ? "今日主角" : ["气氛担当", "朋友局主角", "整活认证", "状态拉满"].randomElement() ?? "整活认证",
            quote: preview ? "有点东西，但不完全承认" : ["这波确实有点东西", "群友看完很难不点头", "截图已经替你保留证据", "节目效果已经给到了"].randomElement() ?? "这波确实有点东西",
            finalComment: "结果仅供朋友间娱乐，开心最重要。",
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
}
