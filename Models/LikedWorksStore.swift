import Foundation
import Combine

/// 本地持久化"已点赞作品 ID 集合"。每个用户在本机上一个作品只能点一次，
/// 不依赖后端去重——后端没有点赞表。卸载/换设备会丢失，可接受。
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

    private func persist() {
        let snapshot = Array(liked)
        queue.async {
            UserDefaults.standard.set(snapshot, forKey: self.key)
        }
    }
}
