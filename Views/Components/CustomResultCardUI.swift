import SwiftUI

/// 用户自定义玩法生成的卡片：直接列出「字段名：用户填的值」，没有花哨样式。
/// 通过 ImageExportManager.renderImage 导出成图片。
struct CustomResultCardUI: View {
    let templateName: String
    let authorName: String
    /// 有序字段-值列表，按用户在编辑器里定义的顺序展示。
    let fields: [(label: String, value: String)]
    var showWatermark: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text(templateName)
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(.themeTextMain)
                if !authorName.isEmpty {
                    Text("by \(authorName)")
                        .font(.system(size: 13))
                        .foregroundColor(.themeTextSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, 24)

            // Field list
            VStack(alignment: .leading, spacing: 14) {
                ForEach(fields.indices, id: \.self) { i in
                    let entry = fields[i]
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.label)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.themeTextSecondary)
                        Text(entry.value.isEmpty ? "—" : entry.value)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.themeTextMain)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(24)

            if showWatermark {
                HStack {
                    Spacer()
                    Text("整活局 · zhenghuo")
                        .font(.system(size: 11))
                        .foregroundColor(.themeTextSecondary.opacity(0.7))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            } else {
                Color.clear.frame(height: 16)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.themePrimary.opacity(0.18), Color.themePrimary.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
}
