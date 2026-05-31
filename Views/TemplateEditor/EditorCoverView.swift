import SwiftUI
import PhotosUI

struct EditorCoverView: View {
    @ObservedObject var draft: TemplateDraft
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var aspectChoice: AspectChoice = .threeFour
    @State private var rawImage: UIImage? = nil   // 原图，切换比例时重新裁
    @State private var isProcessing = false

    enum AspectChoice: CaseIterable {
        case threeFour, fourFive

        var label: String {
            switch self {
            case .threeFour: return "3:4"
            case .fourFive: return "4:5"
            }
        }
        var ratio: CGFloat {
            switch self {
            case .threeFour: return 3.0 / 4.0
            case .fourFive: return 4.0 / 5.0
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                // 预览框 - 始终是裁后比例
                cropPreview
                    .padding(.horizontal, 24)

                // 比例切换
                ratioPicker
                    .padding(.horizontal, 24)

                // 选图按钮
                PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text(rawImage == nil ? "选择图片" : "重新选择")
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.themeTextMain)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.themePrimary)
                    .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .onChange(of: selectedItem) { newItem in
                    Task { await loadImage(item: newItem) }
                }

                tipFooter
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
            .padding(.top, 16)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text("封面图片")
                    .font(.system(size: 18, weight: .bold))
                Image(systemName: "sparkles")
                    .foregroundColor(.themePrimary)
                    .font(.system(size: 13))
            }
            Text("将自动按所选比例从中心裁剪。横图也没问题。")
                .font(.system(size: 12))
                .foregroundColor(.themeTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var cropPreview: some View {
        let ratio = aspectChoice.ratio
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.08))

            if let image = draft.coverImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "plus.photo")
                        .font(.system(size: 36))
                        .foregroundColor(.gray.opacity(0.6))
                    Text("点下面按钮选择图片")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }

            if isProcessing {
                ProgressView().scaleEffect(1.2)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(ratio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.themePrimary.opacity(0.4), lineWidth: 2)
        )
    }

    private var ratioPicker: some View {
        HStack(spacing: 10) {
            Text("封面比例")
                .font(.system(size: 13))
                .foregroundColor(.themeTextSecondary)

            ForEach(AspectChoice.allCases, id: \.self) { choice in
                Button(action: { setAspect(choice) }) {
                    Text(choice.label)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(aspectChoice == choice ? .themeTextMain : .themeTextSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(aspectChoice == choice ? Color.themePrimary : Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
            }

            Spacer()
        }
    }

    private var tipFooter: some View {
        HStack(spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.themePrimary)
            VStack(alignment: .leading, spacing: 2) {
                Text("建议把标题和主体放在画面中间")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.themeTextMain)
                Text("两侧留白，避免被裁切")
                    .font(.system(size: 12))
                    .foregroundColor(.themeTextSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.themePrimary.opacity(0.08))
        .cornerRadius(12)
    }

    private func setAspect(_ choice: AspectChoice) {
        guard aspectChoice != choice else { return }
        aspectChoice = choice
        if let raw = rawImage {
            draft.coverImage = AspectCropper.centerCrop(raw, aspect: choice.ratio)
        }
    }

    private func loadImage(item: PhotosPickerItem?) async {
        guard let item = item else { return }
        await MainActor.run { isProcessing = true }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                let cropped = AspectCropper.centerCrop(uiImage, aspect: aspectChoice.ratio)
                await MainActor.run {
                    self.rawImage = uiImage
                    self.draft.coverImage = cropped
                    self.isProcessing = false
                }
                return
            }
        } catch {
            // fall through
        }
        await MainActor.run { self.isProcessing = false }
    }
}
