
+3
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            BrowseHistoryStore.shared.record(template: template)
        }
    }
}

WorkDetailView.swift
