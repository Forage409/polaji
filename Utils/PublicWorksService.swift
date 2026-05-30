import Foundation
import Combine

class PublicWorksService {
    static let shared = PublicWorksService()
    
    private var baseURL: String {
        Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? "https://api.zhenghuoju.com"
    }
    
    private init() {}
    
    func fetchWorksFeed(completion: @escaping ([PublicWork]?) -> Void) {
        // GET /api/works/feed
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            DispatchQueue.main.async {
                completion([])
            }
        }
    }
    
    func fetchWorkDetail(id: String, completion: @escaping (PublicWork?) -> Void) {
        // GET /api/works/:id
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
    
    func publishWork(title: String, description: String, isAnonymous: Bool, tags: [String], templateId: String, category: String, imageData: Data, completion: @escaping (Bool) -> Void) {
        // POST /api/uploads/work to get R2 URL, then POST /api/works to create metadata
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
            DispatchQueue.main.async {
                completion(true)
            }
        }
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
