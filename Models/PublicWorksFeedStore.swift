import Foundation
import Combine

@MainActor
final class PublicWorksFeedStore: ObservableObject {
    static let shared = PublicWorksFeedStore()

    @Published private(set) var works: [PublicWork] = []
    @Published private(set) var hasMore = true

    private var isRefreshing = false
    private var isLoadingMore = false
    private let pageSize = 20

    private init() {}

    func refresh() async throws {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        let fetched = try await PublicWorksService.shared.fetchWorksFeed(limit: pageSize)
        works = fetched
        hasMore = fetched.count == pageSize
    }

    func loadMore() async throws {
        guard !isLoadingMore, hasMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        let fetched = try await PublicWorksService.shared.fetchWorksFeed(offset: works.count, limit: pageSize)
        let knownIds = Set(works.map(\.id))
        works += fetched.filter { !knownIds.contains($0.id) }
        hasMore = fetched.count == pageSize
    }

    func remove(id: String) {
        works.removeAll { $0.id == id }
    }

    func restore(_ work: PublicWork, at index: Int? = nil) {
        guard !works.contains(where: { $0.id == work.id }) else { return }
        works.insert(work, at: min(index ?? 0, works.count))
    }

    func updateLike(id: String, count: Int) {
        guard let index = works.firstIndex(where: { $0.id == id }) else { return }
        works[index].likeCount = count
    }
}
