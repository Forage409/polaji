import SwiftUI

struct EditorResultRulesView: View {
    @ObservedObject var draft: TemplateDraft
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("配置生成结果")
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    HStack {
                        Text("结果卡片类型")
                            .font(.system(size: 14))
                            .frame(width: 80, alignment: .leading)
                        Picker("", selection: $draft.resultRule.type) {
                            Text("鉴定卡").tag("diagnostic")
                            Text("判决书").tag("verdict")
                            Text("排行榜").tag("ranking")
                            Text("任务卡").tag("task")
                            Text("人设卡").tag("persona")
                        }
                        .pickerStyle(MenuPickerStyle())
                        Spacer()
                    }
                    
                    HStack {
                        Text("标题模板")
                            .font(.system(size: 14))
                            .frame(width: 80, alignment: .leading)
                        TextField("如：隐藏财力鉴定卡", text: $draft.resultRule.titleTemplate)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("副标题模板")
                            .font(.system(size: 14))
                            .frame(width: 80, alignment: .leading)
                        TextField("如：{nickname} 的今日诊断", text: $draft.resultRule.subtitleTemplate)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal)
                
                Text("文案库 (未来将支持多条随机)")
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
            .padding(.vertical)
        }
    }
}
