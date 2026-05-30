import Foundation

struct Template: Identifiable {
    let id: String
    let name: String
    let category: String
    let description: String
    let coverImage: String
    let isVip: Bool
    var usageCount: Int
    let tags: [String]
    let fields: [String]
}

extension Template {
    init(from remote: RemoteTemplate) {
        self.id = remote.id
        self.name = remote.title
        self.category = remote.category
        self.description = remote.description
        self.coverImage = remote.coverImage
        self.isVip = false
        self.usageCount = remote.usageCount
        self.tags = []
        self.fields = []
    }
}
