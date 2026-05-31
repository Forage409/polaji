import Foundation
import SwiftUI

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

enum TemplateInputLimits {
    static let title = 15
    static let description = 120
    static let maxFields = 8
    static let fieldLabel = 12
    static let placeholder = 30
    static let option = 16
    static let minOptions = 2
    static let maxOptions = 8
    static let minParticipants = 2
    static let maxParticipants = 12
    static let textAnswer = 80
}

enum TemplateDraftValidator {
    static func firstError(title: String, description: String, fields: [TemplateField]) -> String? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty { return "请填写玩法标题" }
        if trimmedTitle.count > TemplateInputLimits.title { return "玩法标题最多 \(TemplateInputLimits.title) 个字" }
        if trimmedDescription.isEmpty { return "请填写玩法描述" }
        if trimmedDescription.count > TemplateInputLimits.description { return "玩法描述最多 \(TemplateInputLimits.description) 个字" }
        if fields.isEmpty { return "请至少添加一个填写项" }
        if fields.count > TemplateInputLimits.maxFields { return "填写项最多 \(TemplateInputLimits.maxFields) 个" }

        var labels = Set<String>()
        for field in fields {
            let label = field.label.trimmingCharacters(in: .whitespacesAndNewlines)
            if label.isEmpty { return "每个填写项都需要起一个名字" }
            if label.count > TemplateInputLimits.fieldLabel { return "填写项「\(label)」最多 \(TemplateInputLimits.fieldLabel) 个字" }
            if !labels.insert(label).inserted { return "填写项名称不能重复：「\(label)」" }

            if field.placeholder.count > TemplateInputLimits.placeholder {
                return "填写项「\(label)」的提示语最多 \(TemplateInputLimits.placeholder) 个字"
            }

            if field.type == .singleSelect || field.type == .multiSelect {
                let options = field.options.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                if options.count < TemplateInputLimits.minOptions { return "「\(label)」至少需要 \(TemplateInputLimits.minOptions) 个选项" }
                if options.count > TemplateInputLimits.maxOptions { return "「\(label)」最多支持 \(TemplateInputLimits.maxOptions) 个选项" }
                if options.contains(where: { $0.isEmpty }) { return "「\(label)」存在空选项" }
                if options.contains(where: { $0.count > TemplateInputLimits.option }) { return "「\(label)」的选项最多 \(TemplateInputLimits.option) 个字" }
                if Set(options).count != options.count { return "「\(label)」存在重复选项" }
            }

            if field.type == .participants {
                let minCount = field.minCount ?? 3
                let maxCount = field.maxCount ?? 8
                if minCount < TemplateInputLimits.minParticipants || maxCount > TemplateInputLimits.maxParticipants || minCount > maxCount {
                    return "「\(label)」人数范围需在 \(TemplateInputLimits.minParticipants)-\(TemplateInputLimits.maxParticipants) 人之间"
                }
            }
        }
        return nil
    }
}

extension Binding where Value == String {
    static func limited(_ source: Binding<String>, maxLength: Int) -> Binding<String> {
        Binding(
            get: { source.wrappedValue },
            set: { source.wrappedValue = String($0.prefix(maxLength)) }
        )
    }
}
