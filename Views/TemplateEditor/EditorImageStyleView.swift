import SwiftUI

/// 玩法生成卡片的视觉样式：背景主题、圆角、装饰开关、标题对齐。
/// 仅影响最终生成的卡片，不影响填写页。
struct EditorImageStyleView: View {
    @ObservedObject var draft: TemplateDraft

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                // 实时预览
                preview
                    .padding(.horizontal, 16)

                // 背景主题
                section(title: "背景主题") {
                    bgChooser
                }

                // 圆角
                section(title: "圆角强度") {
                    cornerChooser
                }

                // 标题对齐
                section(title: "标题排版") {
                    alignChooser
                }

                // 装饰开关
                section(title: "装饰元素") {
                    decorationToggles
                }

                Spacer(minLength: 40)
            }
            .padding(.vertical, 16)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text("图片样式")
                    .font(.system(size: 18, weight: .bold))
                Image(systemName: "wand.and.stars")
                    .foregroundColor(.themePrimary)
                    .font(.system(size: 13))
            }
            Text("打造更好看的结果图，提升分享率。")
                .font(.system(size: 12))
                .foregroundColor(.themeTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var preview: some View {
        let sampleFields: [(label: String, value: String)] = previewSample()
        CustomResultCardUI(
            templateName: draft.title.isEmpty ? "玩法标题" : draft.title,
            authorName: "预览",
            fields: sampleFields,
            style: draft.cardStyle
        )
    }

    private func previewSample() -> [(label: String, value: String)] {
        let visible = draft.fields.prefix(3)
        if visible.isEmpty {
            return [("昵称", "小幽灵"), ("心情", "开心")]
        }
        return visible.map { f in
            (f.label, sampleValue(for: f))
        }
    }

    private func sampleValue(for field: TemplateField) -> String {
        switch field.type {
        case .text: return "示例内容"
        case .number: return "88"
        case .singleSelect: return field.options.first ?? "选项 A"
        case .multiSelect: return field.options.prefix(2).joined(separator: "、")
        case .participants: return "小明、小美、阿杰"
        }
    }

    @ViewBuilder
    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.themeTextMain)
                .padding(.horizontal, 24)
            content()
                .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private var bgChooser: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TemplateCardStyle.Background.allCases, id: \.self) { bg in
                    let selected = draft.cardStyle.background == bg
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(StyleRenderer.gradient(for: bg))
                                .frame(width: 64, height: 64)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(selected ? Color.themePrimary : Color.clear, lineWidth: 3)
                                )
                            if selected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.themePrimary)
                                    .background(Circle().fill(Color.white))
                                    .offset(x: 22, y: -22)
                            }
                        }
                        Text(bg.displayName)
                            .font(.system(size: 11))
                            .foregroundColor(selected ? .themeTextMain : .themeTextSecondary)
                    }
                    .onTapGesture { draft.cardStyle.background = bg }
                }
            }
            .padding(.horizontal, 8)
        }
    }

    @ViewBuilder
    private var cornerChooser: some View {
        HStack(spacing: 10) {
            ForEach(TemplateCardStyle.CornerLevel.allCases, id: \.self) { level in
                let selected = draft.cardStyle.corner == level
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: level.radius / 2)
                        .fill(Color.themePrimary.opacity(selected ? 0.4 : 0.15))
                        .frame(height: 36)
                    Text(level.displayName)
                        .font(.system(size: 12))
                        .foregroundColor(selected ? .themeTextMain : .themeTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(selected ? Color.themePrimary.opacity(0.12) : Color.gray.opacity(0.06))
                .cornerRadius(12)
                .onTapGesture { draft.cardStyle.corner = level }
            }
        }
    }

    @ViewBuilder
    private var alignChooser: some View {
        HStack(spacing: 10) {
            ForEach(TemplateCardStyle.TitleAlign.allCases, id: \.self) { align in
                let selected = draft.cardStyle.titleAlign == align
                HStack(spacing: 6) {
                    Image(systemName: align == .center ? "text.aligncenter" : "text.alignleft")
                    Text(align.displayName)
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(selected ? .themeTextMain : .themeTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selected ? Color.themePrimary.opacity(0.18) : Color.gray.opacity(0.06))
                .cornerRadius(12)
                .onTapGesture { draft.cardStyle.titleAlign = align }
            }
        }
    }

    @ViewBuilder
    private var decorationToggles: some View {
        VStack(spacing: 0) {
            decoToggle(label: "✦ 星星", isOn: Binding(
                get: { draft.cardStyle.showStars },
                set: { draft.cardStyle.showStars = $0 }
            ))
            Divider().padding(.leading, 16)
            decoToggle(label: "❤︎ 爱心", isOn: Binding(
                get: { draft.cardStyle.showHearts },
                set: { draft.cardStyle.showHearts = $0 }
            ))
            Divider().padding(.leading, 16)
            decoToggle(label: "✧ 彩纸", isOn: Binding(
                get: { draft.cardStyle.showConfetti },
                set: { draft.cardStyle.showConfetti = $0 }
            ))
            Divider().padding(.leading, 16)
            decoToggle(label: "♕ 徽章", isOn: Binding(
                get: { draft.cardStyle.showBadge },
                set: { draft.cardStyle.showBadge = $0 }
            ))
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
    }

    private func decoToggle(label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.themeTextMain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .tint(.themePrimary)
    }
}
