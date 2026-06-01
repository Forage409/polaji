import SwiftUI

struct EditorImageStyleView: View {
    @ObservedObject var draft: TemplateDraft
    @ObservedObject private var vip = VipManager.shared
    @State private var showingAIWriter = false
    @State private var showingPaywall = false

    private var previewDocument: ResultCardDocument {
        ResultCardDocument.preview(config: draft.resultConfig, title: draft.title, fields: draft.fields)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                aiWriterEntry

                UnifiedResultCardUI(document: previewDocument)
                    .frame(maxWidth: .infinity)

                section(title: "结果版式", hint: "选择最适合玩法内容的排版") {
                    layoutPicker
                }

                section(title: "默认主题", hint: "生成结果时默认使用") {
                    themePicker
                }

                section(title: "参与者可切换主题", hint: "至少保留默认主题") {
                    allowedThemes
                }

                section(title: "默认主贴纸", hint: "可在生成结果后替换") {
                    heroStickerPicker
                }

                section(title: "默认装饰贴纸", hint: "最多选择 3 个") {
                    decorationPicker
                }

                section(title: "结果模块", hint: "控制展示内容和顺序") {
                    moduleEditor
                }

                Spacer(minLength: 40)
            }
            .padding(.vertical, 16)
        }
        .sheet(isPresented: $showingAIWriter) {
            AITemplateCopySheet(draft: draft)
        }
        .sheet(isPresented: $showingPaywall) {
            NavigationStack {
                VIPPaywallView(context: .publisherAI)
            }
        }
    }

    private var aiWriterEntry: some View {
        Button {
            if vip.isVip {
                showingAIWriter = true
            } else {
                showingPaywall = true
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "wand.and.stars")
                    .foregroundColor(Color(hex: "7B61FF"))
                VStack(alignment: .leading, spacing: 3) {
                    Text("AI 帮写玩法文案库")
                        .font(.system(size: 14, weight: .bold))
                    Text(draft.resultConfig.copyLibrary == nil ? "自动生成指标、证据和结论" : "已采用 AI 文案，可继续重新生成")
                        .font(.system(size: 12))
                        .foregroundColor(.themeTextSecondary)
                }
                Spacer()
                if !vip.isVip {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.themeTextSecondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.themeTextSecondary)
            }
            .foregroundColor(.themeTextMain)
            .padding(14)
            .background(Color.white)
            .cornerRadius(14)
            .padding(.horizontal, 20)
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text("结果图设计")
                    .font(.system(size: 18, weight: .bold))
                Image(systemName: "wand.and.stars")
                    .foregroundColor(.themePrimary)
            }
            Text("发布者先定好默认模板，参与者生成后还能轻量换肤。")
                .font(.system(size: 12))
                .foregroundColor(.themeTextSecondary)
        }
        .padding(.horizontal, 24)
    }

    private func section<Content: View>(title: String, hint: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.themeTextMain)
                Text(hint)
                    .font(.system(size: 11))
                    .foregroundColor(.themeTextSecondary)
            }
            .padding(.horizontal, 20)
            content()
        }
    }

    private var layoutPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ResultLayoutPreset.allCases) { layout in
                    choiceChip(
                        title: layout.displayName,
                        selected: draft.resultConfig.layout == layout
                    ) {
                        draft.resultConfig.layout = layout
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var themePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ResultThemePack.all) { pack in
                    themeCard(pack, selected: draft.resultConfig.defaultThemePackId == pack.id) {
                        selectDefaultTheme(pack)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var allowedThemes: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ResultThemePack.all) { pack in
                    let selected = draft.resultConfig.allowedThemePackIds.contains(pack.id)
                    choiceChip(title: pack.displayName, selected: selected) {
                        toggleAllowedTheme(pack.id)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var heroStickerPicker: some View {
        let pack = ResultThemePack.find(draft.resultConfig.defaultThemePackId)
        return HStack(spacing: 12) {
            ForEach(pack.heroStickers, id: \.self) { name in
                stickerButton(name, selected: draft.resultConfig.defaultHeroStickerId == name) {
                    draft.resultConfig.defaultHeroStickerId = name
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private var decorationPicker: some View {
        let pack = ResultThemePack.find(draft.resultConfig.defaultThemePackId)
        return HStack(spacing: 12) {
            ForEach(pack.decorationStickers, id: \.self) { name in
                stickerButton(name, selected: draft.resultConfig.defaultDecorationStickerIds.contains(name)) {
                    toggleDecoration(name)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private var moduleEditor: some View {
        VStack(spacing: 8) {
            ForEach(draft.resultConfig.moduleOrder) { module in
                HStack(spacing: 10) {
                    Image(systemName: module.isRequired ? "lock.fill" : "square.stack.3d.up.fill")
                        .foregroundColor(module.isRequired ? .themeTextSecondary : .themePrimary)
                        .frame(width: 20)
                    Text(module.displayName)
                        .font(.system(size: 14, weight: .medium))
                    Spacer()
                    if !module.isRequired {
                        Button(action: { toggleModule(module) }) {
                            Image(systemName: draft.resultConfig.hiddenModules.contains(module) ? "eye.slash" : "eye")
                        }
                    }
                    Button(action: { moveModule(module, offset: -1) }) {
                        Image(systemName: "chevron.up")
                    }
                    Button(action: { moveModule(module, offset: 1) }) {
                        Image(systemName: "chevron.down")
                    }
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.themeTextMain)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(Color.white)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 20)
    }

    private func themeCard(_ pack: ResultThemePack, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 5) {
                ZStack {
                    Image.bundle(pack.backgrounds[0])
                        .resizable()
                        .scaledToFill()
                    pack.cardColor.opacity(0.28)
                    Image.bundle(pack.heroStickers[0])
                        .resizable()
                        .scaledToFit()
                        .padding(6)
                }
                .frame(width: 108, height: 92)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                Text(pack.displayName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.themeTextMain)
                Text(pack.tagline)
                    .font(.system(size: 10))
                    .foregroundColor(.themeTextSecondary)
                    .lineLimit(1)
            }
            .padding(8)
            .background(selected ? Color.themePrimary.opacity(0.22) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selected ? Color.themePrimary : Color.clear, lineWidth: 2)
            )
            .cornerRadius(14)
        }
    }

    private func stickerButton(_ imageName: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image.bundle(imageName)
                .resizable()
                .scaledToFit()
                .padding(6)
                .frame(width: 58, height: 58)
                .background(selected ? Color.themePrimary.opacity(0.2) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selected ? Color.themePrimary : Color.clear, lineWidth: 2)
                )
                .cornerRadius(12)
        }
    }

    private func choiceChip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.themeTextMain)
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(selected ? Color.themePrimary : Color.white)
                .cornerRadius(16)
        }
    }

    private func selectDefaultTheme(_ pack: ResultThemePack) {
        draft.resultConfig.defaultThemePackId = pack.id
        if !draft.resultConfig.allowedThemePackIds.contains(pack.id) {
            draft.resultConfig.allowedThemePackIds.append(pack.id)
        }
        draft.resultConfig.defaultHeroStickerId = pack.heroStickers.first
        draft.resultConfig.defaultDecorationStickerIds = Array(pack.decorationStickers.prefix(2))
    }

    private func toggleAllowedTheme(_ id: String) {
        guard id != draft.resultConfig.defaultThemePackId else { return }
        if let index = draft.resultConfig.allowedThemePackIds.firstIndex(of: id) {
            draft.resultConfig.allowedThemePackIds.remove(at: index)
        } else {
            draft.resultConfig.allowedThemePackIds.append(id)
        }
    }

    private func toggleDecoration(_ name: String) {
        if let index = draft.resultConfig.defaultDecorationStickerIds.firstIndex(of: name) {
            draft.resultConfig.defaultDecorationStickerIds.remove(at: index)
        } else if draft.resultConfig.defaultDecorationStickerIds.count < 3 {
            draft.resultConfig.defaultDecorationStickerIds.append(name)
        }
    }

    private func toggleModule(_ module: ResultModuleKind) {
        if let index = draft.resultConfig.hiddenModules.firstIndex(of: module) {
            draft.resultConfig.hiddenModules.remove(at: index)
        } else {
            let visibleContent = draft.resultConfig.moduleOrder.filter {
                !$0.isRequired && !draft.resultConfig.hiddenModules.contains($0)
            }
            if visibleContent.count > 1 {
                draft.resultConfig.hiddenModules.append(module)
            }
        }
    }

    private func moveModule(_ module: ResultModuleKind, offset: Int) {
        guard let index = draft.resultConfig.moduleOrder.firstIndex(of: module) else { return }
        let destination = index + offset
        guard draft.resultConfig.moduleOrder.indices.contains(destination) else { return }
        draft.resultConfig.moduleOrder.swapAt(index, destination)
    }
}
