import Foundation
import Combine

class RemoteCreatorService {
    static let shared = RemoteCreatorService()
    
    private var baseURL: String {
        Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? "https://zhenghuo.miaogou.site"
    }
    
    private init() {}
    
    func fetchCreatorDashboard(completion: @escaping (CreatorDashboard?) -> Void) {
        // Need user authentication context here eventually, for now assuming backend resolves via token/cookie or param
        guard let url = URL(string: "\(baseURL)/api/creator/dashboard") else {
            completion(nil)
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, error == nil {
                let dashboard = try? JSONDecoder().decode(CreatorDashboard.self, from: data)
                DispatchQueue.main.async { completion(dashboard) }
            } else {
                DispatchQueue.main.async { completion(nil) }
            }
        }.resume()
    }
    
    func fetchMyPublishedTemplates(completion: @escaping ([RemoteTemplate]?) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/creator/templates") else {
            completion(nil)
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, error == nil {
                let templates = try? JSONDecoder().decode([RemoteTemplate].self, from: data)
                DispatchQueue.main.async { completion(templates) }
            } else {
                DispatchQueue.main.async { completion(nil) }
            }
        }.resume()
    }
}
