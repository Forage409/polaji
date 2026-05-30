import Foundation

class APIClient {
    static let shared = APIClient()
    
    private var baseURL: String {
        Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? "https://zhenghuo.miaogou.site"
    }
    
    private init() {}
    
    func createRequest(path: String, method: String = "GET", body: Data? = nil, headers: [String: String]? = nil) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.unknown(statusCode: 0)
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Inject identity headers
        let identityManager = AnonymousIdentityManager.shared
        request.setValue(identityManager.currentUserId, forHTTPHeaderField: "X-Anonymous-User-Id")
        request.setValue("Bearer \(identityManager.currentInstallToken)", forHTTPHeaderField: "Authorization")
        
        // Add custom headers
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let body = body {
            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            request.httpBody = body
        }
        return request
    }
    
    func performRequest<T: Decodable>(request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的响应"]))
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                print("Decoding failed for \(request.url?.absoluteString ?? ""): \(error)")
                throw APIError.decodingFailed
            }
        case 401, 403:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 500...599:
            throw APIError.serverError
        default:
            throw APIError.unknown(statusCode: httpResponse.statusCode)
        }
    }
    
    func performActionRequest(request: URLRequest) async throws -> Bool {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的响应"]))
        }

        switch httpResponse.statusCode {
        case 200...299:
            return true
        case 401, 403:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 500...599:
            // Try to parse error details from response
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMsg = errorJson["error"] as? String,
               let details = errorJson["details"] as? String {
                throw APIError.serverError(message: "\(errorMsg): \(details)")
            }
            throw APIError.serverError(message: nil)
        default:
            throw APIError.unknown(statusCode: httpResponse.statusCode)
        }
    }
    
    func upload(path: String, data: Data, contentType: String) async throws -> String {
        let request = try createRequest(path: path, method: "POST", body: data, headers: ["Content-Type": contentType])

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的响应"]))
        }

        switch httpResponse.statusCode {
        case 200...299:
            if let urlStr = String(data: responseData, encoding: .utf8) {
                return urlStr
            } else {
                throw APIError.decodingFailed
            }
        case 401, 403:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 500...599:
            // Try to parse error details from response
            if let errorJson = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
               let errorMsg = errorJson["error"] as? String,
               let details = errorJson["details"] as? String {
                throw APIError.serverError(message: "\(errorMsg): \(details)")
            }
            throw APIError.serverError(message: "图片上传失败")
        default:
            throw APIError.unknown(statusCode: httpResponse.statusCode)
        }
    }
}
