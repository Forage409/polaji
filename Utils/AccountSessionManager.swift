import Foundation
import Security
import Combine
import SwiftUI

final class AccountSessionManager: ObservableObject {
    static let shared = AccountSessionManager()

    private let serviceName = "com.zhenghuoju.app.account"
    private let tokenAccount = "sessionToken"
    private let userIdAccount = "accountUserId"
    private let installIdAccount = "clientInstallId"
    private let legacyServiceName = "com.zhenghuoju.app.identity"

    @Published private(set) var isAuthenticated: Bool
    @Published private(set) var isRestoring = true
    private(set) var currentSessionToken: String
    private(set) var currentUserId: String
    let clientInstallId: String

    private init() {
        let accountService = "com.zhenghuoju.app.account"
        currentSessionToken = Self.load(service: accountService, account: "sessionToken") ?? ""
        currentUserId = Self.load(service: accountService, account: "accountUserId") ?? ""
        isAuthenticated = !currentSessionToken.isEmpty && !currentUserId.isEmpty

        if let cached = Self.load(service: accountService, account: "clientInstallId") {
            clientInstallId = cached
        } else {
            let generated = UUID().uuidString
            clientInstallId = generated
            Self.save(service: accountService, account: "clientInstallId", value: generated)
        }
    }

    var authorizationHeader: String? {
        currentSessionToken.isEmpty ? nil : "Bearer \(currentSessionToken)"
    }

    var legacyCredentials: (userId: String, installToken: String)? {
        guard let userId = Self.load(service: legacyServiceName, account: "anonymousUserId"),
              let token = Self.load(service: legacyServiceName, account: "installToken") else {
            return nil
        }
        return (userId, token)
    }

    func restoreSession() async {
        guard isAuthenticated else {
            await MainActor.run { isRestoring = false }
            return
        }
        do {
            let profile = try await AccountService.shared.fetchMe()
            await MainActor.run {
                apply(profile: profile)
                isRestoring = false
            }
        } catch APIError.unauthorized {
            await MainActor.run {
                clearLocalSession()
                isRestoring = false
            }
        } catch {
            await MainActor.run {
                isRestoring = false
            }
        }
    }

    @MainActor
    func accept(receipt: AccountAuthReceipt) {
        currentSessionToken = receipt.token
        currentUserId = receipt.profile.id
        Self.save(service: serviceName, account: tokenAccount, value: receipt.token)
        Self.save(service: serviceName, account: userIdAccount, value: receipt.profile.id)
        withAnimation(.spring(response: 0.68, dampingFraction: 0.82)) {
            isAuthenticated = true
            isRestoring = false
        }
        apply(profile: receipt.profile)
    }

    @MainActor
    func apply(profile: AccountProfile) {
        currentUserId = profile.id
        UserProfileStore.shared.apply(profile: profile)
        VipManager.shared.applyServerStatus(isVip: profile.isVip, plan: profile.vipPlan, until: profile.vipUntil)
    }

    func logout() async {
        try? await AccountService.shared.logout()
        await MainActor.run { clearLocalSession() }
    }

    @MainActor
    func clearLocalSession() {
        Self.delete(service: serviceName, account: tokenAccount)
        Self.delete(service: serviceName, account: userIdAccount)
        currentSessionToken = ""
        currentUserId = ""
        withAnimation(.spring(response: 0.68, dampingFraction: 0.84)) {
            isAuthenticated = false
        }
        UserProfileStore.shared.resetCachedProfile()
        VipManager.shared.deactivate()
    }

    private static func save(service: String, account: String, value: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = Data(value.utf8)
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
    }

    private static func load(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func delete(service: String, account: String) {
        SecItemDelete([
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ] as CFDictionary)
    }
}
