import Foundation
import Combine

class PublicWorksService {
    static let shared = PublicWorksService()
    
    private var baseURL: String {
        Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? "https://zhenghuo.miaogou.site"
    }
    
    private init() {}
    
    func fetchWorksFeed(completion: @escaping ([PublicWork]?) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/works/feed") else {
            completion(nil)
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            do {
                let decoded = try JSONDecoder().decode([PublicWork].self, from: data)
                DispatchQueue.main.async { completion(decoded) }
            } catch {
                print("Failed to decode works feed: \(error)")
                DispatchQueue.main.async { completion(nil) }
            }
        }.resume()
    }
    
    func fetchWorkDetail(id: String, completion: @escaping (PublicWork?) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/works/\(id)") else {
            completion(nil)
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            do {
                let decoded = try JSONDecoder().decode(PublicWork.self, from: data)
                DispatchQueue.main.async { completion(decoded) }
            } catch {
                DispatchQueue.main.async { completion(nil) }
            }
        }.resume()
    }
    
    func publishWork(title: String, description: String, isAnonymous: Bool, tags: [String], templateId: String, category: String, imageData: Data, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/works") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
            "imageUrl": "https://r2.zhenghuoju.com/mock-upload-url" // MOCK R2 FOR NOW
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                completion(error == nil && (response as? HTTPURLResponse)?.statusCode == 200)
            }
        }.resume()
    }
    
    func deleteWork(id: String, completion: @escaping (Bool) -> Void) {
        // DELETE /api/works/:id
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            DispatchQueue.main.async {
                completion(true)
            }
        }
    }
    
    func likeWork(id: String, completion: @escaping (Bool) -> Void) {
        // POST /api/works/:id/like
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
            DispatchQueue.main.async {
                completion(true)
            }
        }
    }
    
    func reportWork(id: String, completion: @escaping (Bool) -> Void) {
        // POST /api/works/:id/report
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
            DispatchQueue.main.async {
                completion(true)
            }
        }
    }
}
