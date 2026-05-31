import Foundation

/// 用户自定义模板字段。`label` 是字段标题，`type` 决定填表时的控件，`options` 给单/多选用。
struct TemplateField: Codable, Identifiable, Equatable {
    enum FieldKind: String, Codable, CaseIterable {
        case text          // 单行文本
        case singleSelect  // 单选
        case multiSelect   // 多选

        var displayName: String {
            switch self {
            case .text: return "单行文本"
            case .singleSelect: return "单选"
            case .multiSelect: return "多选"
            }
        }
    }

    var id: String = UUID().uuidString
    var label: String
    var type: FieldKind
    var placeholder: String = ""
    var options: [String] = []   // 仅 single/multi select 使用
}

/// 用于持久化字段清单到 templates.form_config_raw（JSON）。
struct TemplateFormConfig: Codable {
    var fields: [TemplateField]

    static let empty = TemplateFormConfig(fields: [])

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
        return .empty
    }
}
