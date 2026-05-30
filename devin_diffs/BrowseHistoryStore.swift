import Foundation
import Combine
 
struct BrowseHistoryEntry: Codable, Identifiable, Hashable {
    let id: String
    let templateId: String
    let templateName: String
    let coverImage: String
    let category: String
    let visitedAt: Date
}
 
final class BrowseHistoryStore: ObservableObject {
    static let shared = BrowseHistoryStore()
    
    private let historyKey = "ZhengHuoJu_BrowseHistory"
    private let maxEntries = 50
    
    @Published var entries: [BrowseHistoryEntry] = []
    
    private init() {
        load()
    }
    
    func record(template: Template) {
        let entry = BrowseHistoryEntry(
            id: UUID().uuidString,
            templateId: template.id,
            templateName: template.name,
            coverImage: template.coverImage,
            category: template.category,
            visitedAt: Date()
        )
        entries.removeAll { $0.templateId == template.id }
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
        persist()
    }
    
    func clear() {
        entries = []
        persist()
    }
    
    func remove(id: String) {
        entries.removeAll { $0.id == id }
        persist()
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        if let decoded = try? decoder.decode([BrowseHistoryEntry].self, from: data) {
            self.entries = decoded
        }
    }
    
    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        if let data = try? encoder.encode(entries) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }
}

MockData.swift
