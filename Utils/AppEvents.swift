import Foundation

enum AppEvents {
    static let templatesChanged = Notification.Name("TemplatesChanged")
    static let publicWorksChanged = Notification.Name("PublicWorksChanged")
    static let selectTemplatesTab = Notification.Name("SelectTemplatesTab")

    static func postTemplatesChanged() {
        NotificationCenter.default.post(name: templatesChanged, object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("RefreshFeed"), object: nil)
    }

    static func postPublicWorksChanged() {
        NotificationCenter.default.post(name: publicWorksChanged, object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("RefreshWorksFeed"), object: nil)
    }
}
