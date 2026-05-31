import Foundation
import UIKit
import Combine

class TemplateDraft: ObservableObject {
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var category: String = "趣味"
    @Published var tags: [String] = []

    @Published var coverImage: UIImage? = nil

    /// 所见即所得字段清单。用户在编辑器里看到/改动什么，就是用户填表时看到/改动什么。
    @Published var fields: [TemplateField] = [
        TemplateField(label: "昵称", type: .text, placeholder: "请输入昵称")
    ]
}
