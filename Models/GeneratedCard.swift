import Foundation

struct StatItem: Codable, Identifiable {
    var id = UUID()
    let name: String
    let value: Int
}

struct GeneratedCard: Codable, Identifiable {
    let id: String
    let templateId: String
    let title: String
    let subtitle: String
    let mainImageName: String
    let stats: [StatItem]
    let quote: String
    let createdAt: String
}
