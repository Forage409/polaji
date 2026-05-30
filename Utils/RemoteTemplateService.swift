import Foundation
import Combine

class RemoteTemplateService {
    static let shared = RemoteTemplateService()
    
    // Dynamic base URL from Info.plist
    private var baseURL: String {
        Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? "https://api.zhenghuoju.com"
    }
    
    private init() {}
    
    func fetchTemplates(completion: @escaping ([RemoteTemplate]?) -> Void) {
        // Mock implementation for now
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            DispatchQueue.main.async {
                completion(nil) // Return nil to fallback to local mock data for now
            }
        }
    }
    
    func fetchTemplateDetail(id: String, completion: @escaping (RemoteTemplate?) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
    
    func fetchFeaturedTemplates(completion: @escaping ([RemoteTemplate]?) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
    
    func fetchTrendingTemplates(completion: @escaping ([RemoteTemplate]?) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
    
    func createTemplate(draft: RemoteTemplate, completion: @escaping (Bool) -> Void) {
        // POST /api/templates
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            DispatchQueue.main.async {
                completion(true)
            }
        }
    }
    
    func updateTemplate(template: RemoteTemplate, completion: @escaping (Bool) -> Void) {
        // PUT /api/templates/:id
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            DispatchQueue.main.async {
                completion(true)
            }
        }
    }
    
    func uploadCover(imageData: Data, completion: @escaping (String?) -> Void) {
        // Get pre-signed URL from Worker, then PUT to R2
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
            DispatchQueue.main.async {
                completion("https://r2.zhenghuoju.com/mock_cover_\(UUID().uuidString).jpg")
            }
        }
    }
    
    func publishTemplate(id: String, completion: @escaping (Bool) -> Void) {
        // POST /api/templates/:id/publish
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            DispatchQueue.main.async {
                completion(true)
            }
        }
    }
    
    func sendTemplateEvent(templateId: String, eventType: String) {
        // Events: template_view, template_start, template_generate, template_share, template_like
        // POST /api/templates/:id/events
        print("RemoteTemplateService: Sent event '\(eventType)' for template '\(templateId)'")
    }
}
