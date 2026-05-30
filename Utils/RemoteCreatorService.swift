import Foundation

class RemoteCreatorService {
    static let shared = RemoteCreatorService()
    
    private init() {}
    
    func fetchCreatorDashboard() async throws -> CreatorDashboard {
        let request = try APIClient.shared.createRequest(path: "/api/creator/dashboard")
        return try await APIClient.shared.performRequest(request: request)
    }
    
    func fetchMyPublishedTemplates() async throws -> [RemoteTemplate] {
        let request = try APIClient.shared.createRequest(path: "/api/creator/templates")
        return try await APIClient.shared.performRequest(request: request)
    }
    
    func fetchTemplateStats(templateId: String) async throws -> TemplateStats {
        let request = try APIClient.shared.createRequest(path: "/api/creator/templates/\(templateId)/stats")
        return try await APIClient.shared.performRequest(request: request)
    }
    
    func hideTemplate(templateId: String) async throws -> Bool {
        let request = try APIClient.shared.createRequest(path: "/api/creator/templates/\(templateId)/hide", method: "POST")
        return try await APIClient.shared.performActionRequest(request: request)
    }
    
    func deleteTemplate(templateId: String) async throws -> Bool {
        let request = try APIClient.shared.createRequest(path: "/api/creator/templates/\(templateId)", method: "DELETE")
        return try await APIClient.shared.performActionRequest(request: request)
    }
    
    func updateTemplateStatus(templateId: String, status: String) async throws -> Bool {
        let payload = ["status": status]
        let body = try? JSONSerialization.data(withJSONObject: payload)
        let request = try APIClient.shared.createRequest(path: "/api/creator/templates/\(templateId)/status", method: "PUT", body: body)
        return try await APIClient.shared.performActionRequest(request: request)
    }
}


