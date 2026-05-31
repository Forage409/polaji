import SwiftUI

/// 所见即所得编辑器：长得就跟用户最终填表的页面一样，每一项可以直接改。
struct EditorFormRulesView: View {
    @ObservedObject var draft: TemplateDraft

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("使用者会看到这些填写项。点任何一项即可修改名称、改类型、加选项或删除。")
                    .font(.system(size: 13))
                    .foregroundColor(.themeTextSecondary)
                    .padding(.horizontal, 20)

                ForEach($draft.fields) { $field in
                    fieldEditorCard(field: $field)
                        .padding(.horizontal, 16)
                }

                Button(action: addField) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("新增一项")
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.themePrimary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.themePrimary.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer(minLength: 40)
            }
            .padding(.vertical, 16)
        }
    }

    private func addField() {
        draft.fields.append(
            TemplateField(label: "新填写项", type: .text, placeholder: "请输入")
        )
    }

    @ViewBuilder
    private func fieldEditorCard(field: Binding<TemplateField>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题行：可编辑的名称 + 删除按钮
            HStack(spacing: 8) {
                TextField("填写项名称", text: field.label)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.themeTextMain)

                Spacer()

                Button(action: {
                    if let idx = draft.fields.firstIndex(where: { $0.id == field.wrappedValue.id }) {
                        draft.fields.remove(at: idx)
                    }
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.7))
                }
            }

            // 类型选择
            Picker("", selection: field.type) {
                ForEach(TemplateField.FieldKind.allCases, id: \.self) { kind in
                    Text(kind.displayName).tag(kind)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            // 类型对应的预览/选项编辑区
            switch field.wrappedValue.type {
            case .text:
                TextField("使用者填空时的占位提示，如：请输入昵称", text: field.placeholder)
                    .padding(10)
                    .background(Color.gray.opacity(0.06))
                    .cornerRadius(8)
                    .font(.system(size: 14))

            case .singleSelect, .multiSelect:
                optionsEditor(for: field)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
    }

    @ViewBuilder
    private func optionsEditor(for field: Binding<TemplateField>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("选项（使用者只能从下面里选）")
                .font(.system(size: 12))
                .foregroundColor(.themeTextSecondary)

            ForEach(field.options.indices, id: \.self) { i in
                HStack {
                    TextField("选项 \(i + 1)", text: field.options[i])
                        .padding(8)
                        .background(Color.gray.opacity(0.06))
                        .cornerRadius(8)
                        .font(.system(size: 14))

                    Button(action: {
                        var current = field.wrappedValue
                        if i < current.options.count {
                            current.options.remove(at: i)
                            field.wrappedValue = current
                        }
                    }) {
                        Image(systemName: "minus.circle")
                            .foregroundColor(.red.opacity(0.6))
                    }
                }
            }

            Button(action: {
                var current = field.wrappedValue
                current.options.append("新选项")
                field.wrappedValue = current
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("加选项")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.themePrimary)
            }
            .padding(.top, 2)
        }
    }
}
