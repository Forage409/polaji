import SwiftUI

/// 答题字段编排：每行一卡，可改名/改类型/加选项/删；下方四种"新增"按钮一行铺；
/// 再下方一个简化版"填写页预览"，所见即所得。
struct EditorFormRulesView: View {
    @ObservedObject var draft: TemplateDraft

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // 标题区
                sectionHeader(
                    title: "答题字段编排",
                    hint: "点击可编辑，长按可拖动调整顺序"
                )

                // 字段卡片清单
                fieldsList

                // 新增按钮面板（4 种类型）
                sectionHeader(title: "新增字段", hint: "")
                addFieldGrid
                    .padding(.horizontal, 16)

                // 填写页预览
                sectionHeader(title: "填写页预览", hint: "实时预览")
                previewCard
                    .padding(.horizontal, 16)

                Spacer(minLength: 40)
            }
            .padding(.vertical, 16)
        }
    }

    // MARK: - Section header
    private func sectionHeader(title: String, hint: String) -> some View {
        HStack {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.themeTextMain)
                Image(systemName: "sparkle")
                    .foregroundColor(.themePrimary)
                    .font(.system(size: 10))
            }
            Spacer()
            if !hint.isEmpty {
                Text(hint)
                    .font(.system(size: 11))
                    .foregroundColor(.themeTextSecondary)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Field list
    @ViewBuilder
    private var fieldsList: some View {
        VStack(spacing: 10) {
            ForEach($draft.fields) { $field in
                FieldEditorCard(
                    field: $field,
                    onDelete: {
                        if let idx = draft.fields.firstIndex(where: { $0.id == field.id }) {
                            draft.fields.remove(at: idx)
                        }
                    },
                    onMoveUp: {
                        if let idx = draft.fields.firstIndex(where: { $0.id == field.id }), idx > 0 {
                            draft.fields.swapAt(idx, idx - 1)
                        }
                    },
                    onMoveDown: {
                        if let idx = draft.fields.firstIndex(where: { $0.id == field.id }),
                           idx < draft.fields.count - 1 {
                            draft.fields.swapAt(idx, idx + 1)
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Add field grid
    private var addFieldGrid: some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: cols, spacing: 10) {
            addButton(label: "文本", icon: "textformat", color: Color(red: 1.00, green: 0.85, blue: 0.42)) {
                addField(.text)
            }
            addButton(label: "单选", icon: "circle.lefthalf.filled", color: Color(red: 0.95, green: 0.55, blue: 0.65)) {
                addField(.singleSelect)
            }
            addButton(label: "多选", icon: "checklist", color: Color(red: 0.55, green: 0.45, blue: 0.95)) {
                addField(.multiSelect)
            }
            addButton(label: "数字", icon: "number", color: Color(red: 0.30, green: 0.75, blue: 0.55)) {
                addField(.number)
            }
        }
    }

    @ViewBuilder
    private func addButton(label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.18))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 18, weight: .bold))
                }
                Text("新增\(label)")
                    .font(.system(size: 12))
                    .foregroundColor(.themeTextMain)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
        }
    }

    private func addField(_ kind: TemplateField.FieldKind) {
        let defaults: TemplateField
        switch kind {
        case .text:
            defaults = TemplateField(label: "新文本项", type: .text, placeholder: "请输入")
        case .number:
            defaults = TemplateField(label: "新数字项", type: .number, placeholder: "请输入数字")
        case .singleSelect:
            defaults = TemplateField(label: "新单选项", type: .singleSelect, options: ["选项 A", "选项 B"])
        case .multiSelect:
            defaults = TemplateField(label: "新多选项", type: .multiSelect, options: ["选项 A", "选项 B"])
        case .participants:
            defaults = TemplateField(label: "参与人", type: .participants, minCount: 3, maxCount: 8)
        }
        draft.fields.append(defaults)
    }

    // MARK: - Preview
    @ViewBuilder
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(draft.fields) { field in
                previewFieldRow(field)
            }
            if draft.fields.isEmpty {
                Text("还没有字段。点上面「新增」按钮加一个吧。")
                    .font(.system(size: 13))
                    .foregroundColor(.themeTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(20)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    @ViewBuilder
    private func previewFieldRow(_ field: TemplateField) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.themePrimary.opacity(0.18))
                    .frame(width: 32, height: 32)
                Image(systemName: field.type.icon)
                    .foregroundColor(.themePrimary)
                    .font(.system(size: 14))
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(field.label.isEmpty ? "未命名" : field.label)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.themeTextMain)
                    Text("(\(field.type.displayName))")
                        .font(.system(size: 11))
                        .foregroundColor(.themeTextSecondary)
                    Spacer()
                }

                switch field.type {
                case .text, .number:
                    Text(field.placeholder.isEmpty ? "(空白输入框)" : field.placeholder)
                        .font(.system(size: 12))
                        .foregroundColor(.themeTextSecondary)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.06))
                        .cornerRadius(6)
                case .singleSelect:
                    FlowLayout(spacing: 6) {
                        ForEach(field.options, id: \.self) { opt in
                            optionChip(opt, color: Color(red: 0.95, green: 0.55, blue: 0.65))
                        }
                    }
                case .multiSelect:
                    FlowLayout(spacing: 6) {
                        ForEach(field.options, id: \.self) { opt in
                            optionChip(opt, color: Color(red: 0.55, green: 0.45, blue: 0.95))
                        }
                    }
                case .participants:
                    Text("最少 \(field.minCount ?? 3) 人，最多 \(field.maxCount ?? 8) 人")
                        .font(.system(size: 12))
                        .foregroundColor(.themeTextSecondary)
                }
            }
        }
        .padding(.bottom, 8)
    }

    private func optionChip(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

// MARK: - Single field editor card
private struct FieldEditorCard: View {
    @Binding var field: TemplateField
    let onDelete: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void

    @State private var expanded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.themePrimary.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: field.type.icon)
                        .foregroundColor(.themePrimary)
                        .font(.system(size: 16))
                }

                VStack(alignment: .leading, spacing: 2) {
                    TextField("填写项名称", text: $field.label)
                        .font(.system(size: 15, weight: .bold))
                    Text(field.type.displayName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.themePrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.themePrimary.opacity(0.15))
                        .cornerRadius(6)
                }

                Spacer()

                // Up / Down / Delete
                Button(action: onMoveUp) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.themeTextSecondary)
                        .padding(6)
                        .background(Circle().fill(Color.gray.opacity(0.1)))
                }
                Button(action: onMoveDown) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.themeTextSecondary)
                        .padding(6)
                        .background(Circle().fill(Color.gray.opacity(0.1)))
                }
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.red.opacity(0.7))
                        .padding(6)
                        .background(Circle().fill(Color.red.opacity(0.1)))
                }
            }

            // Type picker
            Picker("", selection: $field.type) {
                ForEach(TemplateField.FieldKind.allCases, id: \.self) { k in
                    Text(k.displayName).tag(k)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            // Body per type
            switch field.type {
            case .text, .number:
                TextField(
                    field.type == .number ? "提示语，如：输入年龄" : "提示语，如：请输入昵称",
                    text: $field.placeholder
                )
                .padding(10)
                .background(Color.gray.opacity(0.06))
                .cornerRadius(8)
                .font(.system(size: 13))

            case .singleSelect, .multiSelect:
                optionsEditor
            case .participants:
                participantsEditor
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
    }

    @ViewBuilder
    private var optionsEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("选项")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.themeTextSecondary)

            ForEach(field.options.indices, id: \.self) { i in
                HStack {
                    TextField("选项 \(i + 1)", text: $field.options[i])
                        .padding(8)
                        .background(Color.gray.opacity(0.06))
                        .cornerRadius(6)
                        .font(.system(size: 13))
                    Button(action: {
                        if i < field.options.count {
                            field.options.remove(at: i)
                        }
                    }) {
                        Image(systemName: "minus.circle")
                            .foregroundColor(.red.opacity(0.6))
                    }
                }
            }
            Button(action: { field.options.append("新选项") }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("加选项")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.themePrimary)
            }
            .padding(.top, 2)
        }
    }

    @ViewBuilder
    private var participantsEditor: some View {
        HStack(spacing: 12) {
            countStepper(label: "最少", value: Binding(
                get: { field.minCount ?? 3 },
                set: { field.minCount = max(1, $0) }
            ))
            countStepper(label: "最多", value: Binding(
                get: { field.maxCount ?? 8 },
                set: { field.maxCount = max(field.minCount ?? 3, $0) }
            ))
        }
    }

    private func countStepper(label: String, value: Binding<Int>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.themeTextSecondary)
            Spacer()
            Button(action: { value.wrappedValue -= 1 }) {
                Image(systemName: "minus.circle.fill").foregroundColor(.themePrimary)
            }
            Text("\(value.wrappedValue)")
                .frame(minWidth: 28)
                .font(.system(size: 14, weight: .bold))
            Button(action: { value.wrappedValue += 1 }) {
                Image(systemName: "plus.circle.fill").foregroundColor(.themePrimary)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.06))
        .cornerRadius(8)
    }
}
