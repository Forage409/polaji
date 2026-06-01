import Foundation

struct AccountProfile: Codable {
    let id: String
    let displayId: String
    let phoneMasked: String
    let nickname: String
    let bio: String
    let avatar: String
    let isVip: Bool
    let vipPlan: String
    let vipUntil: String
}

struct AccountAuthReceipt: Codable {
    let token: String
    let profile: AccountProfile
}

struct AccountProfileReceipt: Codable {
    let profile: AccountProfile
}

struct SMSChallengeReceipt: Codable {
    let challengeId: String
    let cooldownSeconds: Int
    let expiresInSeconds: Int
}

enum AccountAuthError: LocalizedError {
    case invalidPhone
    case invalidCode
    case invalidNickname
    case invalidPassword
    case termsRequired
    case server(code: String, message: String)
    case unavailable

    var errorDescription: String? {
        switch self {
        case .invalidPhone: return "请输入正确的中国大陆手机号。"
        case .invalidCode: return "请输入短信验证码。"
        case .invalidNickname: return "昵称需要填写 2-12 个字。"
        case .invalidPassword: return "密码需要填写 6-20 位。"
        case .termsRequired: return "请先阅读并同意用户协议和隐私政策。"
        case .unavailable: return "网络繁忙，请稍后重试。"
        case .server(let code, let message):
            switch code {
            case "SMS_RATE_LIMITED": return "验证码发送过于频繁，请稍后再试。"
            case "SMS_NOT_CONFIGURED": return "短信服务尚未完成配置，请联系开发者。"
            case "SMS_UPSTREAM_FAILED": return "验证码服务暂时不可用，请稍后再试。"
            case "SMS_CODE_INVALID": return "验证码错误或已过期。"
            case "ACCOUNT_EXISTS": return "该手机号已经注册，请直接登录。"
            case "ACCOUNT_NOT_FOUND": return "该手机号尚未注册，请先注册。"
            case "ACCOUNT_LOGIN_REQUIRED": return "登录已过期，请重新登录。"
            default: return message.isEmpty ? "请求失败，请稍后重试。" : message
            }
        }
    }
}
