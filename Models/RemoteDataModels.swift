import Foundation

struct RemoteTemplate: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let coverImage: String
    let category: String
    let authorId: String
    let authorName: String
    
    // Stats
    var viewCount: Int
    var startCount: Int
    var generateCount: Int
    var usageCount: Int
    var shareCount: Int
    var likeCount: Int
    var reportCount: Int
    
    var status: String // draft, private, published, hidden, deleted
    let createdAt: String
    var updatedAt: String
    
    // Form and Result configurations are stored as JSON strings or codable structs
    // For now we will keep them as opaque types or mapping to existing models
    let formConfigRaw: String?
    let resultConfigRaw: String?
}

struct PublicWork: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let imageUrl: String
    let authorId: String
    let authorName: String
    let templateId: String
    let category: String
    let isAnonymous: Bool
    let tags: [String]
    
    var likeCount: Int
    var reportCount: Int
    
    let createdAt: String
}

struct PublishedWorkReceipt: Codable {
    let id: String
    let imageUrl: String
    let createdAt: String
}

struct WorkLikeReceipt: Codable {
    let success: Bool
    let likeCount: Int
    let alreadyLiked: Bool
}

struct TemplateStats: Codable {
    let viewCount: Int
    let startCount: Int
    let generateCount: Int
    let shareCount: Int
    let likeCount: Int
    let favoriteCount: Int
    let reportCount: Int
}

struct CreatorDashboard: Codable {
    let publishedCount: Int
    let totalViewCount: Int
    let totalGenerateCount: Int
    let totalShareCount: Int
    let totalLikeCount: Int
}
