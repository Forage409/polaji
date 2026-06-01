import SwiftUI

struct AccountGateView: View {
    @ObservedObject private var session = AccountSessionManager.shared

    var body: some View {
        Group {
            if session.isRestoring {
                ZStack {
                    Color(hex: "FAFAFC").ignoresSafeArea()
                    ProgressView("正在恢复账号...")
                }
            } else if session.isAuthenticated {
                ContentView()
            } else {
                NavigationStack {
                    LoginView()
                }
            }
        }
        .task {
            await session.restoreSession()
        }
    }
}

struct LoginView: View {
    @State private var phone = ""
    @State private var code = ""
    @State private var challengeId = ""
    @State private var cooldown = 0
    @State private var isSending = false
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        AuthPage(title: "登录", subtitle: "欢迎回来，继续你的整活之旅") {
            AuthInputRow(icon: "iphone", placeholder: "请输入手机号", text: $phone, keyboard: .numberPad)
                .onChange(of: phone) { phone = String($0.filter(\.isNumber).prefix(11)) }
            AuthCodeRow(code: $code, cooldown: cooldown, isSending: isSending, action: sendCode)
            AuthPrimaryButton(title: isSubmitting ? "登录中..." : "登录", disabled: isSubmitting, action: submit)
                .padding(.top, 20)
            HStack(spacing: 8) {
                Text("还没有账号？")
                    .foregroundColor(.themeTextSecondary)
                NavigationLink("去注册") { RegisterView() }
                    .foregroundColor(Color(hex: "E8AF16"))
            }
            .font(.system(size: 15))
            .frame(maxWidth: .infinity)
            .padding(.top, 18)
        }
        .toast(isPresented: $showAlert, message: alertMessage)
    }

    private func sendCode() {
        guard !isSending, cooldown == 0 else { return }
        isSending = true
        Task {
            do {
                let receipt = try await AccountService.shared.sendCode(phone: phone, purpose: "login")
                await MainActor.run {
                    challengeId = receipt.challengeId
                    cooldown = receipt.cooldownSeconds
                    isSending = false
                    startCountdown()
                }
            } catch {
                await show(error)
            }
        }
    }

    private func submit() {
        guard !isSubmitting else { return }
        isSubmitting = true
        Task {
            do {
                let receipt = try await AccountService.shared.login(phone: phone, code: code, challengeId: challengeId)
                await MainActor.run {
                    AccountSessionManager.shared.accept(receipt: receipt)
                    isSubmitting = false
                }
            } catch {
                await show(error)
            }
        }
    }

    private func startCountdown() {
        Task {
            while cooldown > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run { cooldown = max(0, cooldown - 1) }
            }
        }
    }

    @MainActor
    private func show(_ error: Error) {
        isSending = false
        isSubmitting = false
        alertMessage = error.localizedDescription
        showAlert = true
    }
}

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var phone = ""
    @State private var code = ""
    @State private var nickname = ""
    @State private var password = ""
    @State private var challengeId = ""
    @State private var cooldown = 0
    @State private var agreed = false
    @State private var isSending = false
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        AuthPage(title: "注册", subtitle: "创建你的整活局账号") {
            AuthInputRow(icon: "iphone", placeholder: "请输入手机号", text: $phone, keyboard: .numberPad)
                .onChange(of: phone) { phone = String($0.filter(\.isNumber).prefix(11)) }
            AuthCodeRow(code: $code, cooldown: cooldown, isSending: isSending, action: sendCode)
            AuthInputRow(icon: "person", placeholder: "请输入昵称（2-12字）", text: $nickname)
                .onChange(of: nickname) { nickname = String($0.prefix(12)) }
            AuthSecureRow(text: $password)
                .onChange(of: password) { password = String($0.prefix(20)) }
            agreement
            AuthPrimaryButton(title: isSubmitting ? "注册中..." : "注册", disabled: isSubmitting, action: submit)
                .padding(.top, 2)
            HStack(spacing: 8) {
                Text("已有账号？")
                    .foregroundColor(.themeTextSecondary)
                Button("立即登录") { dismiss() }
                    .foregroundColor(Color(hex: "E8AF16"))
            }
            .font(.system(size: 15))
            .frame(maxWidth: .infinity)
            .padding(.top, 14)
        }
        .navigationBarBackButtonHidden(false)
        .toast(isPresented: $showAlert, message: alertMessage)
    }

    private var agreement: some View {
        HStack(alignment: .top, spacing: 8) {
            Button { agreed.toggle() } label: {
                Image(systemName: agreed ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(agreed ? .themePrimary : .themeTextSecondary)
            }
            Text("我已阅读并同意")
                .foregroundColor(.themeTextSecondary)
            NavigationLink("《用户协议》") { LegalDocView(kind: .terms) }
                .foregroundColor(Color(hex: "E8AF16"))
            Text("和")
                .foregroundColor(.themeTextSecondary)
            NavigationLink("《隐私政策》") { LegalDocView(kind: .privacy) }
                .foregroundColor(Color(hex: "E8AF16"))
        }
        .font(.system(size: 12))
    }

    private func sendCode() {
        guard !isSending, cooldown == 0 else { return }
        isSending = true
        Task {
            do {
                let receipt = try await AccountService.shared.sendCode(phone: phone, purpose: "register")
                await MainActor.run {
                    challengeId = receipt.challengeId
                    cooldown = receipt.cooldownSeconds
                    isSending = false
                    startCountdown()
                }
            } catch {
                await show(error)
            }
        }
    }

    private func submit() {
        guard !isSubmitting else { return }
        isSubmitting = true
        Task {
            do {
                let receipt = try await AccountService.shared.register(
                    phone: phone,
                    code: code,
                    challengeId: challengeId,
                    nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: password,
                    agreedToTerms: agreed
                )
                await MainActor.run {
                    AccountSessionManager.shared.accept(receipt: receipt)
                    isSubmitting = false
                }
            } catch {
                await show(error)
            }
        }
    }

    private func startCountdown() {
        Task {
            while cooldown > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run { cooldown = max(0, cooldown - 1) }
            }
        }
    }

    @MainActor
    private func show(_ error: Error) {
        isSending = false
        isSubmitting = false
        alertMessage = error.localizedDescription
        showAlert = true
    }
}

private struct AuthPage<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content

    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 9) {
                        Text(title)
                            .font(.system(size: 44, weight: .heavy))
                        Text(subtitle)
                            .font(.system(size: 17))
                            .foregroundColor(.themeTextSecondary)
                    }
                    Spacer()
                    Image.bundle("logo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 88, height: 88)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 5))
                        .shadow(color: .black.opacity(0.08), radius: 8, y: 5)
                }
                .padding(.top, 54)
                .padding(.bottom, 28)

                content
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(
            LinearGradient(
                colors: [Color.white, Color(hex: "FBFBFD"), Color(hex: "F7F8FA")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct AuthInputRow: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 16) {
            AuthIcon(icon: icon)
            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .authFieldStyle()
    }
}

private struct AuthCodeRow: View {
    @Binding var code: String
    let cooldown: Int
    let isSending: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            AuthIcon(icon: "checkmark.shield")
            TextField("请输入验证码", text: $code)
                .keyboardType(.numberPad)
                .onChange(of: code) { code = String($0.filter(\.isNumber).prefix(6)) }
            Divider().frame(height: 28)
            Button(cooldown > 0 ? "\(cooldown)s" : (isSending ? "发送中..." : "获取验证码"), action: action)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(cooldown > 0 ? .themeTextSecondary : Color(hex: "E8AF16"))
                .disabled(cooldown > 0 || isSending)
        }
        .authFieldStyle()
    }
}

private struct AuthSecureRow: View {
    @Binding var text: String
    @State private var visible = false

    var body: some View {
        HStack(spacing: 16) {
            AuthIcon(icon: "lock")
            if visible {
                TextField("请设置密码（6-20位）", text: $text)
            } else {
                SecureField("请设置密码（6-20位）", text: $text)
            }
            Button { visible.toggle() } label: {
                Image(systemName: visible ? "eye" : "eye.slash")
                    .foregroundColor(.themeTextSecondary)
            }
        }
        .authFieldStyle()
    }
}

private struct AuthIcon: View {
    let icon: String

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 21))
            .foregroundColor(Color(hex: "737780"))
            .frame(width: 46, height: 46)
            .background(Color(hex: "FFF9ED"))
            .clipShape(Circle())
    }
}

private struct AuthPrimaryButton: View {
    let title: String
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 19, weight: .heavy))
                .foregroundColor(.themeTextMain)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(Color.themePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: Color.themePrimary.opacity(0.28), radius: 12, y: 6)
        }
        .disabled(disabled)
        .opacity(disabled ? 0.62 : 1)
    }
}

private extension View {
    func authFieldStyle() -> some View {
        self.frame(height: 72)
            .padding(.horizontal, 16)
            .background(Color.white.opacity(0.96))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.06), radius: 14, y: 6)
    }
}
