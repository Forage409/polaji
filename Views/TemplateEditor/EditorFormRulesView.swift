import SwiftUI

struct EditorFormRulesView: View {
    @ObservedObject var draft: TemplateDraft
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("配置表单字段")
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                ForEach($draft.formFields) { $field in
                    formFieldRow(field: $field)
                }
                
                Button(action: {
                    draft.formFields.append(FormFieldDraft(
                        type: "text",
                        label: "新字段",
                        placeholder: "请输入",
                        isRequired: true,
                        options: []
                    ))
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("添加字段")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.themePrimary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    @ViewBuilder
    private func formFieldRow(field: Binding<FormFieldDraft>) -> some View {
        let index = draft.formFields.firstIndex(where: { $0.id == field.wrappedValue.id }) ?? 0
        VStack(spacing: 12) {
            HStack {
                Text("字段 \(index + 1)")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Button(action: { 
                    if let idx = draft.formFields.firstIndex(where: { $0.id == field.wrappedValue.id }) {
                        draft.formFields.remove(at: idx) 
                    }
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            
            HStack {
                Text("标题")
                    .font(.system(size: 14))
                    .frame(width: 60, alignment: .leading)
                TextField("如：被整人昵称", text: field.label)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            HStack {
                Text("类型")
                    .font(.system(size: 14))
                    .frame(width: 60, alignment: .leading)
                Picker("", selection: field.type) {
                    Text("单行文本").tag("text")
                    Text("单选").tag("single_select")
                    Text("多选").tag("multi_select")
                    Text("参与人列表").tag("participant_list")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
