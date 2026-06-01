import SwiftUI

struct OutcomePackageEditorSheet: View {
    @ObservedObject var draft: TemplateDraft
    @Environment(\.dismiss) private var dismiss
    @State private var selectedOutcomeId: String?
    @State private var alertMessage = ""
    @State private var showAlert = false

    private var package: TemplateOutcomePackage {
        draft.resultConfig.outcomePackage ?? TemplateOutcomePackage.starter(fields: draft.fields)
    }

    private var previewConfig: TemplateResultConfig {
        var config = draft.resultConfig
        guard let selectedOutcomeId,
              let selected = package.outcomes.first(where: { $0.id == selectedOutcomeId }) else {
            config.outcomePackage = package
            return config
        }
        config.outcomePackage = TemplateOutcomePackage(
            outcomes: [selected] + package.outcomes.filter { $0.id != selectedOutcomeId },
            weights: package.weights
        )
        return config
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("参与者的选择会累计到不同人设。最高分人设决定最终海报，同分时会稳定选出一个结果。")
                        .font(.system(size: 13))
                        .foregroundColor(.themeTextSecondary)

                    UnifiedResultCardUI(
                        document: ResultCardDocument.preview(
                            config: previewConfig,
                            title: draft.title,
                            fields: draft.fields
                        )
                    )
                    .frame(maxWidth: .infinity)

                    sectionHeader("结果人设", hint: "至少保留 4 个，最多 8 个")
                    ForEach(package.outcomes) { outcome in
                        outcomeCard(outcome)
                    }

                    if package.outcomes.count < 8 {
                        Button(action: addOutcome) {
                            Label("新增结果人设", systemImage: "plus.circle.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.themeTextMain)
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(Color.themePrimary)
                                .cornerRadius(18)
                        }
                    }

                    sectionHeader("答案权重", hint: "只对单选和多选题生效")
                    if selectableFields.isEmpty {
                        Text("先添加单选题或多选题，才能配置人设权重。")
                            .font(.system(size: 13))
                            .foregroundColor(.themeTextSecondary)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(14)
                    } else {
                        ForEach(selectableFields) { field in
                            weightCard(field)
                        }
                    }
                }
                .padding(18)
            }
            .background(Color.themeBackground)
            .navigationTitle("人设与答案权重")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        let normalized = package.normalized()
                        guard normalized.isUsable else {
                            alertMessage = "请至少保留 4 个填写完整的人设。"
                            showAlert = true
                            return
                        }
                        draft.resultConfig.outcomePackage = normalized
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                if draft.resultConfig.outcomePackage == nil {
                    draft.resultConfig.outcomePackage = TemplateOutcomePackage.starter(fields: draft.fields)
                }
                selectedOutcomeId = package.outcomes.first?.id
            }
            .toast(isPresented: $showAlert, message: alertMessage)
        }
    }

    private var selectableFields: [TemplateField] {
        draft.fields.filter { $0.type == .singleSelect || $0.type == .multiSelect }
    }

    private func sectionHeader(_ title: String, hint: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 17, weight: .heavy))
            Text(hint)
                .font(.system(size: 12))
                .foregroundColor(.themeTextSecondary)
        }
    }

    private func outcomeCard(_ outcome: TemplateOutcome) -> some View {
        let selected = selectedOutcomeId == outcome.id
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button {
                    selectedOutcomeId = outcome.id
                } label: {
                    Label(outcome.title.isEmpty ? "未命名人设" : outcome.title, systemImage: selected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(selected ? .themeTextMain : .themeTextSecondary)
                }
                Spacer()
                Button(role: .destructive) {
                    removeOutcome(outcome.id)
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(package.outcomes.count <= 4)
            }

            editorField("人设标题", text: outcomeBinding(outcome.id, \.title), limit: 18)
            editorField("副标题", text: outcomeBinding(outcome.id, \.subtitle), limit: 30)
            editorField("结果等级", text: outcomeBinding(outcome.id, \.resultLevel), limit: 16)
            editorField("分享金句", text: outcomeBinding(outcome.id, \.quote), limit: 36)
            editorField("结论文案", text: outcomeBinding(outcome.id, \.finalComment), limit: 50)
            Text("趣味证据")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.themeTextSecondary)
            ForEach(outcome.evidencePool.indices, id: \.self) { index in
                TextField("证据 \(index + 1)", text: .limited(outcomeEvidenceBinding(outcome.id, index), maxLength: 28))
                    .font(.system(size: 13))
                    .padding(9)
                    .background(Color.gray.opacity(0.06))
                    .cornerRadius(8)
            }
            Text("海报指标")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.themeTextSecondary)
            ForEach(outcome.stats.indices, id: \.self) { index in
                HStack {
                    TextField("指标名称", text: .limited(outcomeStatNameBinding(outcome.id, index), maxLength: 12))
                        .font(.system(size: 13))
                        .padding(9)
                        .background(Color.gray.opacity(0.06))
                        .cornerRadius(8)
                    Stepper(
                        "\(outcomeStatValue(outcome.id, index))%",
                        value: outcomeStatValueBinding(outcome.id, index),
                        in: 0...100,
                        step: 5
                    )
                    .font(.system(size: 12))
                    .frame(width: 116)
                }
            }
            Picker("专属主题", selection: outcomeThemeBinding(outcome.id)) {
                Text("跟随玩法默认主题").tag("")
                ForEach(ResultThemePack.all) { pack in
                    Text(pack.displayName).tag(pack.id)
                }
            }
            .font(.system(size: 13))
        }
        .padding(14)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(selected ? Color.themePrimary : Color.clear, lineWidth: 2)
        )
        .cornerRadius(14)
    }

    private func editorField(_ label: String, text: Binding<String>, limit: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.themeTextSecondary)
            TextField(label, text: .limited(text, maxLength: limit), axis: .vertical)
                .font(.system(size: 13))
                .padding(9)
                .background(Color.gray.opacity(0.06))
                .cornerRadius(8)
        }
    }

    private func weightCard(_ field: TemplateField) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(field.label)
                .font(.system(size: 14, weight: .bold))
            ForEach(field.options, id: \.self) { option in
                VStack(alignment: .leading, spacing: 8) {
                    Text(option)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.themeTextMain)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(package.outcomes) { outcome in
                                VStack(spacing: 5) {
                                    Text(outcome.title)
                                        .font(.system(size: 11, weight: .bold))
                                        .lineLimit(1)
                                        .frame(width: 88)
                                    Stepper(
                                        "\(score(fieldId: field.id, option: option, outcomeId: outcome.id))",
                                        value: scoreBinding(fieldId: field.id, option: option, outcomeId: outcome.id),
                                        in: 0...10
                                    )
                                    .labelsHidden()
                                    Text("\(score(fieldId: field.id, option: option, outcomeId: outcome.id)) 分")
                                        .font(.system(size: 11))
                                        .foregroundColor(.themeTextSecondary)
                                }
                                .padding(8)
                                .background(Color.themePrimary.opacity(0.10))
                                .cornerRadius(10)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
    }

    private func outcomeBinding(_ id: String, _ keyPath: WritableKeyPath<TemplateOutcome, String>) -> Binding<String> {
        Binding(
            get: { package.outcomes.first(where: { $0.id == id })?[keyPath: keyPath] ?? "" },
            set: { value in
                updatePackage { package in
                    guard let index = package.outcomes.firstIndex(where: { $0.id == id }) else { return }
                    package.outcomes[index][keyPath: keyPath] = value
                }
            }
        )
    }

    private func score(fieldId: String, option: String, outcomeId: String) -> Int {
        package.weights.first(where: { $0.fieldId == fieldId && $0.option == option })?.scores[outcomeId] ?? 0
    }

    private func outcomeEvidenceBinding(_ id: String, _ index: Int) -> Binding<String> {
        Binding(
            get: { package.outcomes.first(where: { $0.id == id })?.evidencePool[safe: index] ?? "" },
            set: { value in
                updatePackage { package in
                    guard let outcomeIndex = package.outcomes.firstIndex(where: { $0.id == id }),
                          package.outcomes[outcomeIndex].evidencePool.indices.contains(index) else { return }
                    package.outcomes[outcomeIndex].evidencePool[index] = value
                }
            }
        )
    }

    private func outcomeStatNameBinding(_ id: String, _ index: Int) -> Binding<String> {
        Binding(
            get: { package.outcomes.first(where: { $0.id == id })?.stats[safe: index]?.name ?? "" },
            set: { value in
                updatePackage { package in
                    guard let outcomeIndex = package.outcomes.firstIndex(where: { $0.id == id }),
                          package.outcomes[outcomeIndex].stats.indices.contains(index) else { return }
                    package.outcomes[outcomeIndex].stats[index].name = value
                }
            }
        )
    }

    private func outcomeStatValue(_ id: String, _ index: Int) -> Int {
        package.outcomes.first(where: { $0.id == id })?.stats[safe: index]?.value ?? 0
    }

    private func outcomeStatValueBinding(_ id: String, _ index: Int) -> Binding<Int> {
        Binding(
            get: { outcomeStatValue(id, index) },
            set: { value in
                updatePackage { package in
                    guard let outcomeIndex = package.outcomes.firstIndex(where: { $0.id == id }),
                          package.outcomes[outcomeIndex].stats.indices.contains(index) else { return }
                    package.outcomes[outcomeIndex].stats[index].value = value
                }
            }
        )
    }

    private func outcomeThemeBinding(_ id: String) -> Binding<String> {
        Binding(
            get: { package.outcomes.first(where: { $0.id == id })?.themePackId ?? "" },
            set: { value in
                updatePackage { package in
                    guard let index = package.outcomes.firstIndex(where: { $0.id == id }) else { return }
                    package.outcomes[index].themePackId = value.isEmpty ? nil : value
                    package.outcomes[index].heroStickerId = value.isEmpty ? nil : ResultThemePack.find(value).heroStickers.first
                }
            }
        )
    }

    private func scoreBinding(fieldId: String, option: String, outcomeId: String) -> Binding<Int> {
        Binding(
            get: { score(fieldId: fieldId, option: option, outcomeId: outcomeId) },
            set: { value in
                updatePackage { package in
                    if let index = package.weights.firstIndex(where: { $0.fieldId == fieldId && $0.option == option }) {
                        package.weights[index].scores[outcomeId] = value
                    } else {
                        package.weights.append(OptionOutcomeWeight(fieldId: fieldId, option: option, scores: [outcomeId: value]))
                    }
                }
            }
        )
    }

    private func updatePackage(_ update: (inout TemplateOutcomePackage) -> Void) {
        var copy = package
        update(&copy)
        draft.resultConfig.outcomePackage = copy
    }

    private func addOutcome() {
        updatePackage { package in
            package.outcomes.append(
                TemplateOutcome(
                    title: "新结果人设",
                    subtitle: "一句让人想分享的副标题",
                    resultLevel: "隐藏新人设",
                    quote: "把这里改成适合截图分享的金句。",
                    finalComment: "补充一段简洁、有命中感的结论文案。",
                    evidencePool: ["第一条趣味证据", "第二条趣味证据", "第三条趣味证据"],
                    stats: [TemplateOutcomeStat(name: "匹配指数", value: 88), TemplateOutcomeStat(name: "传播潜力", value: 82)]
                )
            )
        }
    }

    private func removeOutcome(_ id: String) {
        updatePackage { package in
            guard package.outcomes.count > 4 else { return }
            package.outcomes.removeAll { $0.id == id }
            package.weights = package.weights.map { weight in
                var copy = weight
                copy.scores.removeValue(forKey: id)
                return copy
            }
        }
        selectedOutcomeId = package.outcomes.first?.id
    }
}
