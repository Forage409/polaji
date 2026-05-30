import Foundation
import UIKit

struct FormFieldDraft: Identifiable {
    let id = UUID()
    var type: String // text, textarea, single_select, multi_select, participant_list, number, date
    var label: String
    var placeholder: String
    var isRequired: Bool
    var options: [String]
    var minCount: Int?
    var maxCount: Int?
}

struct ResultRuleDraft {
    var type: String // diagnostic, verdict, ranking, task, persona
    var titleTemplate: String
    var subtitleTemplate: String
    var resultLevels: [String]
    var finalComments: [String]
}

class TemplateDraft: ObservableObject {
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var category: String = "趣味"
    @Published var tags: [String] = []
    
    @Published var coverImage: UIImage? = nil
    
    @Published var formFields: [FormFieldDraft] = []
    
    @Published var resultRule: ResultRuleDraft = ResultRuleDraft(
        type: "diagnostic",
        titleTemplate: "",
        subtitleTemplate: "",
        resultLevels: [],
        finalComments: []
    )
}
