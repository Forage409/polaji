import Foundation
import Combine

@MainActor
final class AuthChannelPolicyStore: ObservableObject {
    static let shared = AuthChannelPolicyStore()

    @Published private(set) var policy = AuthChannelPolicy(
        mode: "sms",
        smsRegistrationLimit: 100,
        smsRegistrationUsed: 0,
        smsRegistrationRemaining: 100,
        fallbackThreshold: 10,
        usernameHint: "短信注册用户可直接使用手机号作为用户名登录"
    )
    @Published private(set) var isRefreshing = false
    @Published private(set) var hasResolvedPolicy = false

    private init() {}

    var usesPasswordReserve: Bool {
        policy.usesPasswordReserve
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            policy = try await AccountService.shared.fetchChannelPolicy()
        } catch {
            // A temporary status request failure should not block entry.
        }
        hasResolvedPolicy = true
    }
}
