import Foundation

/// 用户自定义模板字段。`label` 是字段标题，`type` 决定填表时的控件，`options` 给单/多选用。
struct TemplateField: Codable, Identifiable, Equatable {
    enum FieldKind: String, Codable, CaseIterable {
        case text
        case number
        case singleSelect
        case multiSelect
        case participants

        var displayName: String {
            switch self {
            case .text: return "文本"
            case .number: return "数字"
            case .singleSelect: return "单选"
            case .multiSelect: return "多选"
            case .participants: return "多人输入"
            }
        }

        var icon: String {
            switch self {
            case .text: return "textformat"
            case .number: return "number"
            case .singleSelect: return "circle.fill.dotted"
            case .multiSelect: return "checklist"
            case .participants: return "person.3.fill"
            }
        }
    }

    var id: String = UUID().uuidString
    var label: String
    var type: FieldKind
    var placeholder: String = ""
    var options: [String] = []
    /// 仅 participants 用：人数下/上限。
    var minCount: Int? = nil
    var maxCount: Int? = nil
}

/// 卡片视觉样式。决定 ResultView/CustomResultCardUI 怎么画结果卡。
struct TemplateCardStyle: Codable, Equatable {
    enum Background: String, Codable, CaseIterable {
        case purpleHaze, creamYellow, mintGreen, sakuraPink, midnightBlue

        var displayName: String {
            switch self {
            case .purpleHaze: return "紫雾"
            case .creamYellow: return "奶油黄"
            case .mintGreen: return "薄荷绿"
            case .sakuraPink: return "樱花粉"
            case .midnightBlue: return "午夜蓝"
            }
        }
    }

    enum CornerLevel: String, Codable, CaseIterable {
        case low, medium, high

        var displayName: String {
            switch self {
            case .low: return "硬"
            case .medium: return "中"
            case .high: return "圆"
            }
        }
        var radius: CGFloat {
            switch self {
            case .low: return 8
            case .medium: return 20
            case .high: return 36
            }
        }
    }

    enum TitleAlign: String, Codable, CaseIterable {
        case center, leading

        var displayName: String {
            switch self {
            case .center: return "居中"
            case .leading: return "左对齐"
            }
        }
    }

    var background: Background = .purpleHaze
    var corner: CornerLevel = .medium
    var titleAlign: TitleAlign = .center
    var showStars: Bool = true
    var showHearts: Bool = false
    var showConfetti: Bool = true
    var showBadge: Bool = false
}

/// 用于持久化字段清单 + 卡片样式到 templates.form_config_raw。
struct TemplateFormConfig: Codable {
    var fields: [TemplateField]
    var cardStyle: TemplateCardStyle = TemplateCardStyle()

    static let empty = TemplateFormConfig(fields: [])

    init(fields: [TemplateField], cardStyle: TemplateCardStyle = TemplateCardStyle()) {
        self.fields = fields
        self.cardStyle = cardStyle
    }

    func toJSONString() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        if let data = try? encoder.encode(self), let s = String(data: data, encoding: .utf8) {
            return s
        }
        return "{\"fields\":[]}"
    }

    static func parse(_ raw: String?) -> TemplateFormConfig {
        guard let raw = raw, !raw.isEmpty,
              let data = raw.data(using: .utf8) else { return .empty }
        if let cfg = try? JSONDecoder().decode(TemplateFormConfig.self, from: data) {
            return cfg
        }
        // 兼容只存了 {"fields": [...]} 没存 cardStyle 的旧数据：手动拆
        if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let fieldsRaw = dict["fields"],
           let fieldsData = try? JSONSerialization.data(withJSONObject: fieldsRaw),
           let fields = try? JSONDecoder().decode([TemplateField].self, from: fieldsData) {
            return TemplateFormConfig(fields: fields)
        }
        return .empty
    }
}
