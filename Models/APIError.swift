import Foundation

enum APIError: Error, LocalizedError {
    case unauthorized
    case notFound
    case serverError(message: String?)
    case decodingFailed
    case networkError(Error)
    case unknown(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "身份认证已过期，请重新启动应用。"
        case .notFound:
            return "请求的数据不存在。"
        case .serverError(let message):
            if let msg = message {
                return "服务器错误：\(msg)"
            }
            return "服务器开小差了，请稍后再试。"
        case .decodingFailed:
            return "数据解析失败，请检查网络环境或升级应用版本。"
        case .networkError(let err):
            return "网络异常：\(err.localizedDescription)"
        case .unknown(let code):
            return "发生未知错误 (状态码: \(code))"
        }
    }
}
