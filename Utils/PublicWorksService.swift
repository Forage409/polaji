import Foundation

class PublicWorksService {
    static let shared = PublicWorksService()
    
    private init() {}
    
    func fetchWorksFeed() async throws -> [PublicWork] {
        let request = try APIClient.shared.createRequest(path: "/api/works/feed")
        return try await APIClient.shared.performRequest(request: request)
    }
    
    func fetchWorkDetail(id: String) async throws -> PublicWork {
        let request = try APIClient.shared.createRequest(path: "/api/works/\(id)")
        return try await APIClient.shared.performRequest(request: request)
    }
    
    func publishWork(title: String, description: String, isAnonymous: Bool, tags: [String], templateId: String, category: String, imageData: Data) async throws -> Bool {
        // Upload image first
        let imageUrl = try await APIClient.shared.upload(path: "/api/upload", data: imageData, contentType: "image/jpeg")
        
        let payload: [String: Any] = [
            "id": UUID().uuidString,
            "templateId": templateId,
            "title": title,
            "description": description,
            "isAnonymous": isAnonymous,
            "authorId": UserProfileStore.shared.userId,
            "authorName": UserProfileStore.shared.nickname,
            "authorAvatar": UserProfileStore.shared.avatarName,
            "tags": tags,
            "category": category,
            "imageUrl": imageUrl
        ]
        
        let body = try? JSONSerialization.data(withJSONObject: payload)
        let request = try APIClient.shared.createRequest(path: "/api/works", method: "POST", body: body)
        return try await APIClient.shared.performActionRequest(request: request)
    }
    
    func deleteWork(id: String) async throws -> Bool {
        let request = try APIClient.shared.createRequest(path: "/api/works/\(id)", method: "DELETE")
        return try await APIClient.shared.performActionRequest(request: request)
    }
    
    func likeWork(id: String) async throws -> Bool {
        let request = try APIClient.shared.createRequest(path: "/api/works/\(id)/like", method: "POST")
        return try await APIClient.shared.performActionRequest(request: request)
    }
    
    func reportWork(id: String) async throws -> Bool {
        let request = try APIClient.shared.createRequest(path: "/api/works/\(id)/report", method: "POST")
        return try await APIClient.shared.performActionRequest(request: request)
    }
}

