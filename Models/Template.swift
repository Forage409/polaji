import Foundation

struct Template: Identifiable {
    let id: String
    let name: String
    let category: String
    let description: String
    let coverImage: String
    let isVip: Bool
    var usageCount: Int
    let tags: [String]
    let fields: [String]
    /// 用户自定义模板的字段清单。系统内置模板这里为 nil。
    var customFields: [TemplateField]? = nil
    /// 用户自定义模板的卡片样式（背景、圆角、装饰）。
    var cardStyle: TemplateCardStyle = TemplateCardStyle()
    /// 结果图设计配置。官方玩法和用户玩法共用同一套模块化渲染器。
    var resultConfig: TemplateResultConfig = .default
}

extension Template {
    init(from remote: RemoteTemplate) {
        self.id = remote.id
        self.name = remote.title
        self.category = remote.category
        self.description = remote.description
        self.coverImage = remote.coverImage
        self.isVip = false
        self.usageCount = remote.usageCount
        self.tags = []
        self.fields = []
        let cfg = TemplateFormConfig.parse(remote.formConfigRaw)
        self.customFields = cfg.fields.isEmpty ? nil : cfg.fields
        self.cardStyle = cfg.cardStyle
        self.resultConfig = TemplateResultConfig.parse(remote.resultConfigRaw, legacyStyle: cfg.cardStyle)
    }
}
