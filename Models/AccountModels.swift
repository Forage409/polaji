import Foundation

struct AccountProfile: Codable {
    let id: String
    let displayId: String
    let phoneMasked: String
    let username: String?
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

struct AuthChannelPolicy: Codable {
    let mode: String
    let smsRegistrationLimit: Int
    let smsRegistrationUsed: Int
    let smsRegistrationRemaining: Int
    let fallbackThreshold: Int
    let usernameHint: String

    var usesPasswordReserve: Bool { mode == "password" }
}

enum AccountAuthError: LocalizedError {
    case invalidPhone
    case invalidUsername
    case invalidCode
    case invalidNickname
    case invalidPassword
    case termsRequired
    case server(code: String, message: String)
    case unavailable

    var errorDescription: String? {
        switch self {
        case .invalidPhone: return "请输入正确的中国大陆手机号。"
        case .invalidUsername: return "用户名请使用 4-20 位字母、数字或下划线。"
        case .invalidCode: return "请输入短信验证码。"
        case .invalidNickname: return "昵称需要填写 2-12 个字。"
        case .invalidPassword: return "密码需要填写 6-20 位。"
        case .termsRequired: return "请先阅读并同意用户协议和隐私政策。"
        case .unavailable: return "网络繁忙，请稍后重试。"
        case .server(let code, let message):
            switch code {
            case "SMS_RATE_LIMITED": return "验证码发送过于频繁，已为你切换到账号密码登录。"
            case "SMS_NOT_CONFIGURED": return "短信服务暂不可用，已为你切换到账号密码登录。"
            case "SMS_UPSTREAM_FAILED": return "验证码服务暂不可用，已为你切换到账号密码登录。"
            case "SMS_CAPACITY_LOW": return "短信注册名额即将用完，已启用账号密码应急通道。"
            case "SMS_CODE_INVALID": return "验证码错误或已过期。"
            case "ACCOUNT_EXISTS": return "该手机号已经注册。用户名就是手机号，请直接使用密码登录。"
            case "ACCOUNT_NOT_FOUND": return "该手机号尚未注册，请先注册。"
            case "USERNAME_EXISTS": return "该用户名已经被使用，请换一个。"
            case "PASSWORD_INVALID": return "用户名或密码不正确。"
            case "PASSWORD_RESERVE_NOT_ACTIVE": return "当前仍可使用短信注册，请先完成手机号验证。"
            case "AUTH_RATE_LIMITED": return "尝试次数过多，请 15 分钟后再试。"
            case "ACCOUNT_LOGIN_REQUIRED": return "登录已过期，请重新登录。"
            default: return message.isEmpty ? "请求失败，请稍后重试。" : message
            }
        }
    }
}
