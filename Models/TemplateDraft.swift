import Foundation
import UIKit
import Combine

class TemplateDraft: ObservableObject {
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var category: String = "趣味"
    @Published var tags: [String] = []

    @Published var coverImage: UIImage? = nil

    @Published var fields: [TemplateField] = [
        TemplateField(label: "昵称", type: .text, placeholder: "请输入昵称")
    ]

    @Published var cardStyle: TemplateCardStyle = TemplateCardStyle()
    @Published var resultConfig: TemplateResultConfig = .default
}
