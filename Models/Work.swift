import Foundation

struct Work: Identifiable, Codable {
    let id: String
    let templateId: String
    let title: String
    let imagePath: String
    let createdAt: String
    let category: String
    let isShared: Bool
}
