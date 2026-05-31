import SwiftUI

struct PublicWorkDetailView: View {
    let work: PublicWork
    @State private var showingAlert = false
    @State private var alertMessage = ""

    @StateObject private var likeStore = LikedWorksStore.shared
    @State private var likeCount: Int
    @State private var heartScale: CGFloat = 1.0
    @State private var heartFlyOpacity: Double = 0
    @State private var heartFlyOffset: CGFloat = 0
    @State private var isProcessingLike = false

    init(work: PublicWork) {
        self.work = work
        _likeCount = State(initialValue: work.likeCount)
    }

    private var isLiked: Bool { likeStore.isLiked(work.id) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CachedAsyncImage(url: RemoteImageURL.resolve(work.imageUrl)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .aspectRatio(3/4, contentMode: .fit)
                        .overlay(ProgressView())
                }
                .frame(width: 260, height: 325)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 8) {
                    Text(work.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.themeTextMain)

                    HStack(spacing: 8) {
                        Text(work.isAnonymous ? "匿名用户" : work.authorName)
                            .font(.system(size: 13))
                            .foregroundColor(.themeTextSecondary)

                        if !work.category.isEmpty {
                            Text("·")
                                .foregroundColor(.themeTextSecondary)
                            Text(work.category)
                                .font(.system(size: 13))
                                .foregroundColor(.themeTextSecondary)
                        }
                    }

                    if !work.description.isEmpty {
                        Text(work.description)
                            .font(.system(size: 14))
                            .foregroundColor(.themeTextMain)
                            .lineSpacing(4)
                            .padding(.top, 6)
                    }

                    if !work.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(work.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.system(size: 12))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.themePrimary.opacity(0.15))
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 16)

                HStack(spacing: 12) {
                    likeButton

                    Button(action: { saveImage() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.down")
                            Text("保存图片")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.themeTextMain)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.themePrimary)
                        .cornerRadius(22)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle("作品详情")
        .navigationBarTitleDisplayMode(.inline)
        .toast(isPresented: $showingAlert, message: alertMessage)
    }

    private var likeButton: some View {
        Button(action: { tapLike() }) {
            HStack(spacing: 6) {
                ZStack {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .themeTextMain)
                        .scaleEffect(heartScale)

                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .opacity(heartFlyOpacity)
                        .offset(y: heartFlyOffset)
                        .scaleEffect(1.2)
                        .allowsHitTesting(false)
                }
                Text("\(likeCount)")
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.themeTextMain)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(isLiked ? Color.red.opacity(0.12) : Color.themePrimary.opacity(0.15))
            .cornerRadius(22)
        }
        .disabled(isProcessingLike || isLiked)
    }

    private func tapLike() {
        guard !isLiked, !isProcessingLike else { return }

        // Optimistic UI: animate + bump count + persist locally first
        isProcessingLike = true
        likeStore.mark(work.id)
        likeCount += 1

        withAnimation(.spring(response: 0.25, dampingFraction: 0.45)) {
            heartScale = 1.5
        }
        withAnimation(.easeOut(duration: 0.6)) {
            heartFlyOpacity = 1.0
            heartFlyOffset = -40
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                heartScale = 1.0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            heartFlyOpacity = 0
            heartFlyOffset = 0
        }

        Task {
            do {
                let receipt = try await PublicWorksService.shared.likeWork(id: work.id)
                await MainActor.run {
                    likeCount = receipt.likeCount ?? likeCount
                    NotificationCenter.default.post(
                        name: NSNotification.Name("PublicWorkLikeChanged"),
                        object: nil,
                        userInfo: ["id": work.id, "likeCount": likeCount]
                    )
                    isProcessingLike = false
                }
            } catch {
                await MainActor.run {
                    likeStore.unmark(work.id)
                    likeCount = max(0, likeCount - 1)
                    alertMessage = "点赞失败，请稍后重试"
                    showingAlert = true
                    isProcessingLike = false
                }
            }
        }
    }

    private func saveImage() {
        guard let url = RemoteImageURL.resolve(work.imageUrl) else { return }
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else {
                    await MainActor.run {
                        alertMessage = "图片解析失败"
                        showingAlert = true
                    }
                    return
                }
                ImageExportManager.shared.saveImageToPhotos(image) { ok in
                    alertMessage = ok ? "已保存到相册" : "保存失败，请检查相册权限"
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = "下载失败：\(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}
