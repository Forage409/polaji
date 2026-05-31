import SwiftUI

/// 已被「所见即所得」改版废弃，保留空实现避免历史引用编译失败。
/// 不再被 TemplateEditorView 使用，可在下次清理时删除整个文件。
struct EditorResultRulesView: View {
    @ObservedObject var draft: TemplateDraft

    var body: some View {
        EmptyView()
    }
}
