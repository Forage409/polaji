import SwiftUI

@main
struct ZhengHuoJuApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) { phase in
                    guard phase == .active else { return }
                    AppNotificationManager.shared.refresh()
                    Task { await AppNotificationManager.shared.checkForNewTemplates() }
                }
        }
    }
}
