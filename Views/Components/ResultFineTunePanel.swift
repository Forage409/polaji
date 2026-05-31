import SwiftUI

struct ResultFineTunePanel: View {
    @Binding var document: ResultCardDocument
    let allowedThemeIds: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("编辑你的结果图")
                        .font(.system(size: 17, weight: .heavy))
                    Text("换肤、换贴纸、改文案，再分享出去。")
                        .font(.system(size: 12))
                        .foregroundColor(.themeTextSecondary)
                }
                Spacer()
                Button(action: { document.randomizeThemeAssets() }) {
                    Label("随机换一套", systemImage: "shuffle")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.themePrimary)
                        .foregroundColor(.themeTextMain)
                        .cornerRadius(14)
                }
            }

            editorSection("主题") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(availableThemes) { pack in
                            Button(action: { document.applyTheme(pack.id, randomize: true) }) {
                                Text(pack.displayName)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.themeTextMain)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(document.themePackId == pack.id ? Color.themePrimary : Color.white)
                                    .cornerRadius(14)
                            }
                        }
                    }
                }
            }

            editorSection("主贴纸") {
                HStack(spacing: 10) {
                    ForEach(document.themePack.heroStickers, id: \.self) { name in
                        stickerButton(name, selected: document.heroStickerId == name) {
                            document.heroStickerId = name
                        }
                    }
                    Spacer()
                }
            }

            editorSection("角落贴纸") {
                HStack(spacing: 10) {
                    ForEach(document.themePack.decorationStickers, id: \.self) { name in
                        stickerButton(name, selected: document.decorationStickerIds.contains(name)) {
                            toggleDecoration(name)
                        }
                    }
                    Spacer()
                }
            }

            editorSection("文字") {
                VStack(spacing: 9) {
                    limitedField("标题", text: $document.title, limit: 36)
                    limitedField("副标题", text: $document.subtitle, limit: 52)
                    limitedField("结果等级", text: $document.resultLevel, limit: 24)
                    limitedField("趣味文案", text: $document.quote, limit: 72)
                    limitedField("最终结论", text: $document.finalComment, limit: 100)
                    ForEach($document.fields) { $field in
                        limitedField(field.label, text: $field.value, limit: 80)
                    }
                    ForEach(document.evidence.indices, id: \.self) { index in
                        limitedField("内容 \(index + 1)", text: evidenceBinding(index), limit: 80)
                    }
                }
            }

            editorSection("模块顺序") {
                VStack(spacing: 8) {
                    ForEach(document.moduleOrder) { module in
                        HStack {
                            Image(systemName: module.isRequired ? "lock.fill" : "square.stack.3d.up.fill")
                                .foregroundColor(module.isRequired ? .themeTextSecondary : .themePrimary)
                            Text(module.displayName)
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                            if !module.isRequired {
                                Button(action: { toggleModule(module) }) {
                                    Image(systemName: document.hiddenModules.contains(module) ? "eye.slash" : "eye")
                                }
                            }
                            Button(action: { moveModule(module, offset: -1) }) {
                                Image(systemName: "chevron.up")
                            }
                            Button(action: { moveModule(module, offset: 1) }) {
                                Image(systemName: "chevron.down")
                            }
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.themeTextMain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Color.white)
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.themeBackground)
    }

    private var availableThemes: [ResultThemePack] {
        let ids = allowedThemeIds.isEmpty ? [document.themePackId] : allowedThemeIds
        return ResultThemePack.all.filter { ids.contains($0.id) }
    }

    private func editorSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.themeTextSecondary)
            content()
        }
    }

    private func limitedField(_ title: String, text: Binding<String>, limit: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.themeTextSecondary)
            TextField("", text: Binding(
                get: { text.wrappedValue },
                set: { text.wrappedValue = String($0.prefix(limit)) }
            ))
            .font(.system(size: 13))
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .background(Color.white)
            .cornerRadius(9)
        }
    }

    private func stickerButton(_ imageName: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image.bundle(imageName)
                .resizable()
                .scaledToFit()
                .padding(5)
                .frame(width: 52, height: 52)
                .background(selected ? Color.themePrimary.opacity(0.24) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(selected ? Color.themePrimary : Color.clear, lineWidth: 2)
                )
                .cornerRadius(10)
        }
    }

    private func evidenceBinding(_ index: Int) -> Binding<String> {
        Binding(
            get: { document.evidence[index] },
            set: { document.evidence[index] = String($0.prefix(80)) }
        )
    }

    private func toggleDecoration(_ name: String) {
        if let index = document.decorationStickerIds.firstIndex(of: name) {
            document.decorationStickerIds.remove(at: index)
        } else if document.decorationStickerIds.count < 3 {
            document.decorationStickerIds.append(name)
        }
    }

    private func toggleModule(_ module: ResultModuleKind) {
        if document.hiddenModules.contains(module) {
            document.hiddenModules.remove(module)
        } else {
            let visibleContent = document.moduleOrder.filter { !$0.isRequired && !document.hiddenModules.contains($0) }
            if visibleContent.count > 1 {
                document.hiddenModules.insert(module)
            }
        }
    }

    private func moveModule(_ module: ResultModuleKind, offset: Int) {
        guard let index = document.moduleOrder.firstIndex(of: module) else { return }
        let destination = index + offset
        guard document.moduleOrder.indices.contains(destination) else { return }
        document.moduleOrder.swapAt(index, destination)
    }
}
