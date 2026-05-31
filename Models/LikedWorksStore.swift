import Foundation
import Combine

/// 本地持久化"已点赞作品 ID 集合"。每个用户在本机上一个作品只能点一次，
/// 后端仍会按匿名身份去重；本地集合用于即时反馈和避免重复请求。
final class LikedWorksStore: ObservableObject {
    static let shared = LikedWorksStore()

    @Published private(set) var liked: Set<String>

    private let key = "likedWorkIds"
    private let queue = DispatchQueue(label: "com.zhenghuoju.liked", qos: .utility)

    private init() {
        if let arr = UserDefaults.standard.array(forKey: key) as? [String] {
            self.liked = Set(arr)
        } else {
            self.liked = []
        }
    }

    func isLiked(_ id: String) -> Bool {
        liked.contains(id)
    }

    /// 标记为已点赞并持久化。返回是否新点赞（false 表示之前就已点过）。
    @discardableResult
    func mark(_ id: String) -> Bool {
        guard !liked.contains(id) else { return false }
        liked.insert(id)
        persist()
        return true
    }

    func unmark(_ id: String) {
        guard liked.remove(id) != nil else { return }
        persist()
    }

    private func persist() {
        let snapshot = Array(liked)
        queue.async {
            UserDefaults.standard.set(snapshot, forKey: self.key)
        }
    }
}
