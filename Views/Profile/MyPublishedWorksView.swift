import SwiftUI

struct MyPublishedWorksView: View {
    @State private var works: [PublicWork] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var deletingId: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("加载公开作品中...")
            } else if !errorMessage.isEmpty {
                VStack(spacing: 14) {
                    Text(errorMessage)
                        .foregroundColor(.themeTextSecondary)
                    Button("重新加载", action: load)
                        .foregroundColor(.themePrimary)
                }
            } else if works.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 42))
                        .foregroundColor(.themeTextSecondary)
                    Text("还没有公开作品")
                        .font(.system(size: 17, weight: .bold))
                    Text("生成结果后选择「发布到广场」即可在这里管理。")
                        .font(.system(size: 13))
                        .foregroundColor(.themeTextSecondary)
                }
            } else {
                List {
                    ForEach(works) { work in
                        HStack(spacing: 12) {
                            CachedAsyncImage(url: RemoteImageURL.resolve(work.imageUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } placeholder: {
                                Color.gray.opacity(0.12)
                            }
                            .frame(width: 64, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                            VStack(alignment: .leading, spacing: 5) {
                                Text(work.title)
                                    .font(.system(size: 15, weight: .bold))
                                    .lineLimit(2)
                                Text(work.isAnonymous ? "匿名发布" : "公开昵称")
                                    .font(.system(size: 12))
                                    .foregroundColor(.themeTextSecondary)
                            }
                            Spacer()
                            Button(role: .destructive) {
                                delete(work)
                            } label: {
                                if deletingId == work.id {
                                    ProgressView()
                                } else {
                                    Text("撤回")
                                }
                            }
                            .disabled(deletingId != nil)
                        }
                        .padding(.vertical, 5)
                    }
                }
                .listStyle(.plain)
                .refreshable { load() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle("我的公开作品")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: load)
    }

    private func load() {
        isLoading = true
        errorMessage = ""
        Task {
            do {
                let fetched = try await PublicWorksService.shared.fetchMyPublishedWorks()
                await MainActor.run {
                    works = fetched
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "加载失败：\(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }

    private func delete(_ work: PublicWork) {
        deletingId = work.id
        let removedIndex = works.firstIndex(where: { $0.id == work.id })
        works.removeAll { $0.id == work.id }
        PublicWorksFeedStore.shared.remove(id: work.id)
        Task {
            do {
                _ = try await PublicWorksService.shared.deleteWork(id: work.id)
                await MainActor.run {
                    WorksStore.shared.deleteWork(id: work.id)
                    AppEvents.postPublicWorksChanged()
                    deletingId = nil
                }
            } catch {
                await MainActor.run {
                    works.insert(work, at: min(removedIndex ?? 0, works.count))
                    PublicWorksFeedStore.shared.restore(work, at: removedIndex)
                    errorMessage = "撤回失败：\(error.localizedDescription)"
                    deletingId = nil
                }
            }
        }
    }
}
