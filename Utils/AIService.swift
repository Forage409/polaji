import Foundation

enum AITone: String, Codable, CaseIterable, Identifiable {
    case `default`
    case sharp
    case cute
    case absurd
    case formal
    case moments

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .default: return "爆梗优化"
        case .sharp: return "毒舌"
        case .cute: return "可爱"
        case .absurd: return "抽象"
        case .formal: return "正经"
        case .moments: return "朋友圈风"
        }
    }
}

struct AIQuotaStatus: Codable {
    let isVip: Bool
    let limit: Int
    let used: Int
    let remaining: Int
    let window: String
}

struct AIOptimizedCopy: Codable {
    let title: String
    let subtitle: String
    let evidence: [String]
    let resultLevel: String
    let quote: String
    let finalComment: String
    let quota: AIQuotaStatus
}

struct AITemplateCopyReceipt: Codable {
    let stats: [String]
    let evidencePool: [String]
    let finalPool: [String]
    let levels: [String]
    let quota: AIQuotaStatus

    var library: TemplateCopyLibrary {
        TemplateCopyLibrary(stats: stats, evidencePool: evidencePool, finalPool: finalPool, levels: levels)
    }
}

struct AIGamePackageReceipt: Codable {
    let description: String
    let questions: [TemplateField]
    let outcomes: [TemplateOutcome]
    let weights: [OptionOutcomeWeight]
    let quota: AIQuotaStatus

    var package: TemplateOutcomePackage {
        TemplateOutcomePackage(outcomes: outcomes, weights: weights)
    }
}

enum AIServiceError: LocalizedError {
    case quotaExceeded
    case vipRequired
    case requestReplay
    case ugcRejected(String)
    case invalidResponse
    case unavailable
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .quotaExceeded: return "今日 AI 次数已用完，开通 VIP 可获得更多次数。"
        case .vipRequired: return "这项 AI 能力为 VIP 专属。"
        case .requestReplay: return "本次请求已处理，请勿重复提交。"
        case .ugcRejected(let reason): return reason
        case .invalidResponse: return "AI 返回内容不完整，请稍后重试。"
        case .unavailable: return "AI 服务暂时不可用，请稍后重试。"
        case .requestFailed(let message): return message
        }
    }
}

final class AIService {
    static let shared = AIService()

    private init() {}

    func fetchStatus() async throws -> AIQuotaStatus {
        let request = try APIClient.shared.createRequest(path: "/api/ai/status")
        return try await perform(request)
    }

    func optimize(document: ResultCardDocument, userInputs: [String: String], tone: AITone) async throws -> AIOptimizedCopy {
        let payload: [String: Any] = [
            "requestId": UUID().uuidString,
            "templateId": document.templateId,
            "tone": tone.rawValue,
            "userInputs": userInputs,
            "resultDocument": [
                "title": document.title,
                "subtitle": document.subtitle,
                "evidence": document.evidence,
                "resultLevel": document.resultLevel,
                "quote": document.quote,
                "finalComment": document.finalComment
            ]
        ]
        let body = try JSONSerialization.data(withJSONObject: payload)
        let request = try APIClient.shared.createRequest(path: "/api/ai/optimize-result", method: "POST", body: body)
        return try await perform(request)
    }

    func generateTemplateCopy(title: String, description: String, category: String, fields: [TemplateField], tone: AITone) async throws -> AITemplateCopyReceipt {
        let fieldPayload: [[String: Any]] = fields.map { field in
            [
                "label": field.label,
                "type": field.type.rawValue,
                "placeholder": field.placeholder,
                "options": field.options,
                "minCount": field.minCount ?? 0,
                "maxCount": field.maxCount ?? 0,
            ]
        }
        let payload: [String: Any] = [
            "requestId": UUID().uuidString,
            "templateTitle": title,
            "templateDescription": description,
            "category": category,
            "tone": tone.rawValue,
            "workflow": "参与者依次填写编排字段，提交后生成可分享的结果海报。",
            "fields": fieldPayload,
        ]
        let body = try JSONSerialization.data(withJSONObject: payload)
        let request = try APIClient.shared.createRequest(path: "/api/ai/generate-template-copy", method: "POST", body: body)
        return try await perform(request)
    }

    func generateGamePackage(title: String, description: String, category: String, fields: [TemplateField], tone: AITone) async throws -> AIGamePackageReceipt {
        let fieldPayload: [[String: Any]] = fields.map { field in
            [
                "id": field.id,
                "label": field.label,
                "type": field.type.rawValue,
                "placeholder": field.placeholder,
                "options": field.options,
                "minCount": field.minCount ?? 0,
                "maxCount": field.maxCount ?? 0,
            ]
        }
        let payload: [String: Any] = [
            "requestId": UUID().uuidString,
            "templateTitle": title,
            "templateDescription": description,
            "category": category,
            "tone": tone.rawValue,
            "workflow": "参与者依次回答问题，选择题答案按权重命中一个结果人设，再生成可分享的专属海报。",
            "fields": fieldPayload,
        ]
        let body = try JSONSerialization.data(withJSONObject: payload)
        let request = try APIClient.shared.createRequest(path: "/api/ai/generate-game-package", method: "POST", body: body)
        return try await perform(request)
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AIServiceError.unavailable }
        if (200..<300).contains(http.statusCode) {
            guard let decoded = try? JSONDecoder().decode(T.self, from: data) else {
                throw AIServiceError.invalidResponse
            }
            return decoded
        }

        let body = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        switch body?["code"] as? String {
        case "AI_QUOTA_EXCEEDED": throw AIServiceError.quotaExceeded
        case "VIP_REQUIRED": throw AIServiceError.vipRequired
        case "AI_REQUEST_REPLAY": throw AIServiceError.requestReplay
        case "AI_UGC_REJECTED":
            throw AIServiceError.ugcRejected((body?["reason"] as? String) ?? "玩法内容不适合生成，请修改后重试。")
        case "AI_INVALID_RESPONSE": throw AIServiceError.invalidResponse
        case "AI_UPSTREAM_FAILED": throw AIServiceError.unavailable
        default:
            throw AIServiceError.requestFailed((body?["error"] as? String) ?? "AI 请求失败，请稍后重试。")
        }
    }
}
