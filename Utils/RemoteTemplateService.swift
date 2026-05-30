import Foundation

class RemoteTemplateService {
    static let shared = RemoteTemplateService()
    
    private init() {}
    
    func fetchTemplates() async throws -> [RemoteTemplate] {
        let request = try APIClient.shared.createRequest(path: "/api/templates")
        return try await APIClient.shared.performRequest(request: request)
    }
    
    func fetchTemplateDetail(id: String) async throws -> RemoteTemplate {
        let request = try APIClient.shared.createRequest(path: "/api/templates/\(id)")
        return try await APIClient.shared.performRequest(request: request)
    }
    
    func fetchFeaturedTemplates() async throws -> [RemoteTemplate] {
        let request = try APIClient.shared.createRequest(path: "/api/templates/featured")
        return try await APIClient.shared.performRequest(request: request)
    }
    
    func fetchTrendingTemplates() async throws -> [RemoteTemplate] {
        let request = try APIClient.shared.createRequest(path: "/api/templates/trending")
        return try await APIClient.shared.performRequest(request: request)
    }
    
    func createTemplate(draft: RemoteTemplate) async throws -> Bool {
        let body = try? JSONEncoder().encode(draft)
        let request = try APIClient.shared.createRequest(path: "/api/templates", method: "POST", body: body)
        return try await APIClient.shared.performActionRequest(request: request)
    }
    
    func updateTemplate(template: RemoteTemplate) async throws -> Bool {
        let body = try? JSONEncoder().encode(template)
        let request = try APIClient.shared.createRequest(path: "/api/templates/\(template.id)", method: "PUT", body: body)
        return try await APIClient.shared.performActionRequest(request: request)
    }
    
    func uploadCover(imageData: Data) async throws -> String {
        return try await APIClient.shared.upload(path: "/api/upload", data: imageData, contentType: "image/jpeg")
    }
    
    func publishTemplate(id: String) async throws -> Bool {
        let request = try APIClient.shared.createRequest(path: "/api/templates/\(id)/publish", method: "POST")
        return try await APIClient.shared.performActionRequest(request: request)
    }
    
    func sendTemplateEvent(templateId: String, eventType: String) async {
        do {
            let payload = ["eventType": eventType]
            let body = try? JSONSerialization.data(withJSONObject: payload)
            let request = try APIClient.shared.createRequest(path: "/api/templates/\(templateId)/events", method: "POST", body: body)
            let _ = try await APIClient.shared.performActionRequest(request: request)
        } catch {
            print("Failed to send event \(eventType): \(error.localizedDescription)")
        }
    }
}

