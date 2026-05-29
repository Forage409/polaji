import Foundation

struct Template: Identifiable {
    let id: String
    let name: String
    let category: String
    let description: String
    let coverImage: String
    let isVip: Bool
    let usageCount: Int
    let tags: [String]
    let fields: [String]
}
