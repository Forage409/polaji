import SwiftUI

struct PublicWorkDetailView: View {
    let work: PublicWork
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: URL(string: work.imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.15))
                            .aspectRatio(3/4, contentMode: .fit)
                            .overlay(ProgressView())
                    case .success(let image):
                        image.resizable().scaledToFit()
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.15))
                            .aspectRatio(3/4, contentMode: .fit)
                            .overlay(
                                VStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle")
                                    Text("图片加载失败").font(.system(size: 12))
                                }.foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .cornerRadius(16)
                .padding(.horizontal, 16)

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
                    Button(action: { likeAction() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "heart")
                            Text("\(work.likeCount)")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.themeTextMain)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.themePrimary.opacity(0.15))
                        .cornerRadius(22)
                    }

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

    private func likeAction() {
        Task {
            _ = try? await PublicWorksService.shared.likeWork(id: work.id)
            await MainActor.run {
                alertMessage = "已点赞"
                showingAlert = true
            }
        }
    }

    private func saveImage() {
        guard let url = URL(string: work.imageUrl) else { return }
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
