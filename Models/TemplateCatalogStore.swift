import Foundation
import Combine

@MainActor
final class TemplateCatalogStore: ObservableObject {
    static let shared = TemplateCatalogStore()

    @Published private(set) var templates: [Template] = MockData.allTemplates
    @Published private(set) var featuredTemplates: [Template] = MockData.hotTemplates

    private var isRefreshing = false

    private init() {}

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            async let allRequest = RemoteTemplateService.shared.fetchTemplates()
            async let featuredRequest = RemoteTemplateService.shared.fetchFeaturedTemplates()
            let (allRemote, featuredRemote) = try await (allRequest, featuredRequest)
            MockData.updateUsageCounts(from: allRemote)
            templates = mergedTemplates(from: allRemote)
            featuredTemplates = mergedFeatured(from: featuredRemote)
        } catch {
            templates = mergedTemplates(from: [])
            featuredTemplates = MockData.hotTemplates
            print("Failed to refresh template catalog: \(error)")
        }
    }

    func remove(id: String) {
        templates.removeAll { $0.id == id }
        featuredTemplates.removeAll { $0.id == id }
    }

    private func mergedTemplates(from remote: [RemoteTemplate]) -> [Template] {
        let mockIds = Set(MockData.allTemplates.map(\.id))
        let extras = remote
            .filter { !mockIds.contains($0.id) }
            .map(Template.init(from:))
        return MockData.allTemplates + extras
    }

    private func mergedFeatured(from remote: [RemoteTemplate]) -> [Template] {
        let allById = Dictionary(uniqueKeysWithValues: templates.map { ($0.id, $0) })
        let mapped = remote.compactMap { allById[$0.id] ?? Template(from: $0) }
        return mapped.isEmpty ? MockData.hotTemplates : Array(mapped.prefix(4))
    }
}
