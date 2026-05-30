import Foundation

class RemoteCreatorService {
    static let shared = RemoteCreatorService()
    
    private var baseURL: String {
        Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? "https://zhenghuo.miaogou.site"
    }
    
    private init() {}
    
    private func createRequest(path: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.unknown(statusCode: 0)
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // Inject identity
        request.setValue(AnonymousIdentityManager.shared.currentUserId, forHTTPHeaderField: "X-Anonymous-User-Id")
        
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        return request
    }
    
    private func performRequest<T: Decodable>(request: URLRequest) async throws -> T {
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
    
    private func performActionRequest(request: URLRequest) async throws -> Bool {
        let (_, response) = try await URLSession.shared.data(for: request)
        
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
            throw APIError.serverError
        default:
            throw APIError.unknown(statusCode: httpResponse.statusCode)
        }
    }
    
    func fetchCreatorDashboard() async throws -> CreatorDashboard {
        let request = try createRequest(path: "/api/creator/dashboard")
        return try await performRequest(request: request)
    }
    
    func fetchMyPublishedTemplates() async throws -> [RemoteTemplate] {
        let request = try createRequest(path: "/api/creator/templates")
        return try await performRequest(request: request)
    }
    
    func fetchTemplateStats(templateId: String) async throws -> TemplateStats {
        let request = try createRequest(path: "/api/creator/templates/\(templateId)/stats")
        return try await performRequest(request: request)
    }
    
    func hideTemplate(templateId: String) async throws -> Bool {
        let request = try createRequest(path: "/api/creator/templates/\(templateId)/hide", method: "POST")
        return try await performActionRequest(request: request)
    }
    
    func deleteTemplate(templateId: String) async throws -> Bool {
        let request = try createRequest(path: "/api/creator/templates/\(templateId)", method: "DELETE")
        return try await performActionRequest(request: request)
    }
    
    func updateTemplateStatus(templateId: String, status: String) async throws -> Bool {
        let payload = ["status": status]
        let body = try? JSONSerialization.data(withJSONObject: payload)
        let request = try createRequest(path: "/api/creator/templates/\(templateId)/status", method: "PUT", body: body)
        return try await performActionRequest(request: request)
    }
}

