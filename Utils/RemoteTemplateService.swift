import Foundation
import Combine

class RemoteTemplateService {
    static let shared = RemoteTemplateService()
    
    // Dynamic base URL from Info.plist
    private var baseURL: String {
        Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? "https://zhenghuo.miaogou.site"
    }
    
    private init() {}
    
    func fetchTemplates(completion: @escaping ([RemoteTemplate]?) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/templates") else {
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
    
    func fetchTemplateDetail(id: String, completion: @escaping (RemoteTemplate?) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/templates/\(id)") else {
            completion(nil)
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, error == nil {
                let template = try? JSONDecoder().decode(RemoteTemplate.self, from: data)
                DispatchQueue.main.async { completion(template) }
            } else {
                DispatchQueue.main.async { completion(nil) }
            }
        }.resume()
    }
    
    func fetchFeaturedTemplates(completion: @escaping ([RemoteTemplate]?) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/templates/featured") else {
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
    
    func fetchTrendingTemplates(completion: @escaping ([RemoteTemplate]?) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/templates/trending") else {
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
    
    func createTemplate(draft: RemoteTemplate, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/templates") else {
            completion(false)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(draft)
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            let success = error == nil && (response as? HTTPURLResponse)?.statusCode == 200
            DispatchQueue.main.async { completion(success) }
        }.resume()
    }
    
    func updateTemplate(template: RemoteTemplate, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/templates/\(template.id)") else {
            completion(false)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(template)
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            let success = error == nil && (response as? HTTPURLResponse)?.statusCode == 200
            DispatchQueue.main.async { completion(success) }
        }.resume()
    }
    
    func uploadCover(imageData: Data, completion: @escaping (String?) -> Void) {
        // Fallback mock for cover upload to prevent full blockage if R2 is not ready
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
            DispatchQueue.main.async {
                completion("https://r2.zhenghuoju.com/mock_cover_\(UUID().uuidString).jpg")
            }
        }
    }
    
    func publishTemplate(id: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/templates/\(id)/publish") else {
            completion(false)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            let success = error == nil && (response as? HTTPURLResponse)?.statusCode == 200
            DispatchQueue.main.async { completion(success) }
        }.resume()
    }
    
    func sendTemplateEvent(templateId: String, eventType: String) {
        guard let url = URL(string: "\(baseURL)/api/templates/\(templateId)/events") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = ["eventType": eventType]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error = error {
                print("Failed to send event \(eventType): \(error.localizedDescription)")
            } else {
                print("RemoteTemplateService: Sent event '\(eventType)' for template '\(templateId)'")
            }
        }.resume()
    }
}

