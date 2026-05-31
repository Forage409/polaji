import SwiftUI

/// 用户自定义玩法生成的卡片：按 TemplateCardStyle 渲染背景/圆角/装饰。
/// 通过 ImageExportManager.renderImage 导出成图片。
struct CustomResultCardUI: View {
    let templateName: String
    let authorName: String
    /// 有序字段-值列表，按用户在编辑器里定义的顺序展示。
    let fields: [(label: String, value: String)]
    var style: TemplateCardStyle = TemplateCardStyle()
    var showWatermark: Bool = false

    var body: some View {
        ZStack {
            // 装饰层（在背景之上、内容之下）
            decorationLayer
                .allowsHitTesting(false)

            VStack(alignment: alignment, spacing: 18) {
                header

                if style.showBadge {
                    badgeView
                }

                Divider()
                    .background(StyleRenderer.subTextColor(for: style.background).opacity(0.4))

                fieldList

                if showWatermark {
                    HStack {
                        Spacer()
                        Text("整活局 · zhenghuo")
                            .font(.system(size: 11))
                            .foregroundColor(StyleRenderer.subTextColor(for: style.background).opacity(0.7))
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(StyleRenderer.gradient(for: style.background))
        .clipShape(RoundedRectangle(cornerRadius: style.corner.radius))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    private var alignment: HorizontalAlignment {
        style.titleAlign == .center ? .center : .leading
    }

    private var frameAlignment: Alignment {
        style.titleAlign == .center ? .center : .leading
    }

    @ViewBuilder
    private var header: some View {
        VStack(alignment: alignment, spacing: 6) {
            Text(templateName)
                .font(.system(size: 26, weight: .heavy))
                .foregroundColor(StyleRenderer.textColor(for: style.background))
                .multilineTextAlignment(style.titleAlign == .center ? .center : .leading)
                .frame(maxWidth: .infinity, alignment: frameAlignment)
            if !authorName.isEmpty {
                Text("by \(authorName)")
                    .font(.system(size: 13))
                    .foregroundColor(StyleRenderer.subTextColor(for: style.background))
                    .frame(maxWidth: .infinity, alignment: frameAlignment)
            }
        }
    }

    @ViewBuilder
    private var badgeView: some View {
        HStack(spacing: 6) {
            Image(systemName: "rosette")
            Text("荣誉证书")
                .font(.system(size: 13, weight: .bold))
        }
        .foregroundColor(StyleRenderer.accentColor(for: style.background))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.7))
        .cornerRadius(12)
        .frame(maxWidth: .infinity, alignment: frameAlignment)
    }

    @ViewBuilder
    private var fieldList: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(fields.indices, id: \.self) { i in
                let entry = fields[i]
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(StyleRenderer.accentColor(for: style.background))
                            .frame(width: 6, height: 6)
                        Text(entry.label)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(StyleRenderer.subTextColor(for: style.background))
                    }
                    Text(entry.value.isEmpty ? "—" : entry.value)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(StyleRenderer.textColor(for: style.background))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private var decorationLayer: some View {
        let accent = StyleRenderer.accentColor(for: style.background)
        ZStack {
            if style.showStars {
                Group {
                    Image(systemName: "sparkle").position(x: 30, y: 30)
                    Image(systemName: "sparkle").position(x: 280, y: 80).font(.system(size: 12))
                    Image(systemName: "sparkle").position(x: 50, y: 320).font(.system(size: 14))
                }
                .foregroundColor(accent.opacity(0.5))
            }
            if style.showHearts {
                Group {
                    Image(systemName: "heart.fill").position(x: 250, y: 30).font(.system(size: 12))
                    Image(systemName: "heart.fill").position(x: 35, y: 200).font(.system(size: 10))
                }
                .foregroundColor(accent.opacity(0.55))
            }
            if style.showConfetti {
                Group {
                    Circle().frame(width: 6, height: 6).position(x: 80, y: 60)
                    Circle().frame(width: 4, height: 4).position(x: 220, y: 240)
                    Circle().frame(width: 5, height: 5).position(x: 290, y: 360)
                }
                .foregroundColor(accent.opacity(0.45))
            }
        }
    }
}
