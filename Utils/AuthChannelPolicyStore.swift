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
    @Published private(set) var localFallbackReason = ""

    private init() {}

    var usesPasswordReserve: Bool {
        policy.usesPasswordReserve || !localFallbackReason.isEmpty
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            policy = try await AccountService.shared.fetchChannelPolicy()
            if policy.usesPasswordReserve {
                localFallbackReason = "短信注册席位即将用完"
            } else {
                localFallbackReason = ""
            }
        } catch {
            // A temporary status request failure should not block entry.
        }
    }

    func activatePasswordReserve(reason: String) {
        localFallbackReason = reason
    }
}
