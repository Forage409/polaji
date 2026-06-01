import SwiftUI

struct AccountGateView: View {
    @ObservedObject private var session = AccountSessionManager.shared
    @ObservedObject private var policy = AuthChannelPolicyStore.shared

    var body: some View {
        ZStack {
            Color(hex: "FAFAFC").ignoresSafeArea()

            if session.isRestoring || (!session.isAuthenticated && !policy.hasResolvedPolicy) {
                AccountLaunchView()
                    .transition(.opacity.combined(with: .scale(scale: 1.04)))
            } else if session.isAuthenticated {
                ContentView()
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 1.035)),
                            removal: .opacity.combined(with: .scale(scale: 0.97))
                        )
                    )
            } else {
                NavigationStack {
                    LoginView()
                }
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity.combined(with: .scale(scale: 1.04))
                    )
                )
            }
        }
        .animation(.spring(response: 0.72, dampingFraction: 0.84), value: session.isAuthenticated)
        .animation(.easeInOut(duration: 0.42), value: session.isRestoring)
        .task {
            async let restore: Void = session.restoreSession()
            async let refresh: Void = policy.refresh()
            _ = await (restore, refresh)
        }
    }
}

private enum AuthLoginMode: String {
    case sms
    case password
}

struct LoginView: View {
    @ObservedObject private var policy = AuthChannelPolicyStore.shared

    @State private var mode: AuthLoginMode = .sms
    @State private var phone = ""
    @State private var username = ""
    @State private var code = ""
    @State private var password = ""
    @State private var challengeId = ""
    @State private var cooldown = 0
    @State private var isSending = false
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    private var activeMode: AuthLoginMode {
        policy.usesPasswordReserve ? .password : mode
    }

    var body: some View {
        AuthPage(title: "登录", subtitle: "欢迎回来，继续你的整活之旅") {
            AuthModePicker(mode: activeMode, smsDisabled: policy.usesPasswordReserve, onSelect: selectMode)

            Group {
                if activeMode == .sms {
                    AuthInputRow(icon: "iphone", placeholder: "请输入手机号", text: $phone, keyboard: .numberPad)
                        .onChange(of: phone) { phone = String($0.filter(\.isNumber).prefix(11)) }
                    AuthCodeRow(code: $code, cooldown: cooldown, isSending: isSending, action: sendCode)
                } else {
                    AuthInputRow(icon: "person.text.rectangle", placeholder: "请输入用户名或注册手机号", text: $username)
                        .onChange(of: username) { username = String($0.prefix(20)) }
                    AuthSecureRow(text: $password, placeholder: "请输入密码（6-20位）")
                    Text("通过短信注册过？用户名就是你的手机号，直接输入手机号和注册时设置的密码即可登录。")
                        .font(.system(size: 12))
                        .foregroundColor(.themeTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .transition(.opacity)

            AuthPrimaryButton(title: isSubmitting ? "登录中..." : "登录", disabled: isSubmitting, action: submit)
                .padding(.top, 10)

            HStack(spacing: 8) {
                Text("还没有账号？")
                    .foregroundColor(.themeTextSecondary)
                NavigationLink("去注册") {
                    RegisterView { existingPhone in
                        phone = existingPhone
                        username = existingPhone
                        withAnimation(.spring(response: 0.48, dampingFraction: 0.84)) {
                            mode = .password
                        }
                        show(message: "这个手机号已经注册。用户名就是手机号，请输入之前设置的密码。")
                    }
                }
                .foregroundColor(Color(hex: "E8AF16"))
            }
            .font(.system(size: 15))
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
        .toast(isPresented: $showAlert, message: alertMessage, duration: 2.8)
        .task {
            await policy.refresh()
            if policy.usesPasswordReserve {
                switchToPassword()
            }
        }
        .onChange(of: policy.usesPasswordReserve) { enabled in
            if enabled {
                switchToPassword()
            }
        }
    }

    private func selectMode(_ selected: AuthLoginMode) {
        if selected == .sms && policy.usesPasswordReserve {
            show(message: "短信通道已进入应急状态，请使用用户名和密码登录。")
            return
        }
        withAnimation(.spring(response: 0.48, dampingFraction: 0.84)) {
            mode = selected
        }
    }

    private func sendCode() {
        guard !isSending, cooldown == 0 else { return }
        guard !policy.usesPasswordReserve else {
            switchToPassword()
            return
        }
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
                await MainActor.run {
                    if error.accountServerCode == "SMS_CAPACITY_LOW" {
                        Task { await policy.refresh() }
                        switchToPassword()
                    } else {
                        show(error)
                    }
                }
            }
        }
    }

    private func submit() {
        guard !isSubmitting else { return }
        isSubmitting = true
        Task {
            do {
                let receipt: AccountAuthReceipt
                if activeMode == .sms {
                    receipt = try await AccountService.shared.login(phone: phone, code: code, challengeId: challengeId)
                } else {
                    receipt = try await AccountService.shared.passwordLogin(username: username, password: password)
                }
                await MainActor.run {
                    AccountSessionManager.shared.accept(receipt: receipt)
                    isSubmitting = false
                }
            } catch {
                await MainActor.run { show(error) }
            }
        }
    }

    private func switchToPassword() {
        if username.isEmpty { username = phone }
        isSending = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
            mode = .password
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

    private func show(message: String) {
        alertMessage = message
        showAlert = true
    }

    private func show(_ error: Error) {
        isSending = false
        isSubmitting = false
        show(message: error.localizedDescription)
    }
}

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var policy = AuthChannelPolicyStore.shared

    let onExistingAccount: ((String) -> Void)?

    @State private var phone = ""
    @State private var username = ""
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

    init(onExistingAccount: ((String) -> Void)? = nil) {
        self.onExistingAccount = onExistingAccount
    }

    var body: some View {
        AuthPage(title: "注册", subtitle: "创建你的整活局账号") {
            Group {
                if policy.usesPasswordReserve {
                    AuthInputRow(icon: "person.text.rectangle", placeholder: "设置用户名（4-20位字母、数字或下划线）", text: $username)
                        .onChange(of: username) {
                            username = String($0.filter {
                                $0.unicodeScalars.allSatisfy { $0.isASCII } && ($0.isLetter || $0.isNumber || $0 == "_")
                            }.prefix(20))
                        }
                    Text("请记住用户名，后续可直接使用用户名和密码登录。")
                        .font(.system(size: 12))
                        .foregroundColor(.themeTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    AuthInputRow(icon: "iphone", placeholder: "请输入手机号", text: $phone, keyboard: .numberPad)
                        .onChange(of: phone) { phone = String($0.filter(\.isNumber).prefix(11)) }
                    AuthCodeRow(code: $code, cooldown: cooldown, isSending: isSending, action: sendCode)
                }
            }
            .transition(.opacity)

            AuthInputRow(icon: "person", placeholder: "请输入昵称（2-12字）", text: $nickname)
                .onChange(of: nickname) { nickname = String($0.prefix(12)) }
            AuthSecureRow(text: $password, placeholder: "请设置密码（6-20位）")
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
            .padding(.top, 8)
        }
        .navigationBarBackButtonHidden(false)
        .toast(isPresented: $showAlert, message: alertMessage, duration: 2.8)
        .task { await policy.refresh() }
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
        guard !policy.usesPasswordReserve else { return }
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
                await MainActor.run {
                    if error.accountServerCode == "ACCOUNT_EXISTS" {
                        onExistingAccount?(phone)
                        dismiss()
                    } else if error.requestsPasswordFallback {
                        isSending = false
                        if error.accountServerCode == "SMS_CAPACITY_LOW" {
                            Task { await policy.refresh() }
                        } else {
                            show(error)
                        }
                    } else {
                        show(error)
                    }
                }
            }
        }
    }

    private func submit() {
        guard !isSubmitting else { return }
        isSubmitting = true
        Task {
            do {
                let receipt: AccountAuthReceipt
                if policy.usesPasswordReserve {
                    receipt = try await AccountService.shared.passwordReserveRegister(
                        username: username,
                        nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
                        password: password,
                        agreedToTerms: agreed
                    )
                } else {
                    receipt = try await AccountService.shared.register(
                        phone: phone,
                        code: code,
                        challengeId: challengeId,
                        nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
                        password: password,
                        agreedToTerms: agreed
                    )
                }
                await MainActor.run {
                    AccountSessionManager.shared.accept(receipt: receipt)
                    isSubmitting = false
                }
            } catch {
                await MainActor.run { show(error) }
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

    private func show(message: String) {
        alertMessage = message
        showAlert = true
    }

    private func show(_ error: Error) {
        isSending = false
        isSubmitting = false
        show(message: error.localizedDescription)
    }
}

private struct AuthModePicker: View {
    let mode: AuthLoginMode
    let smsDisabled: Bool
    let onSelect: (AuthLoginMode) -> Void

    var body: some View {
        HStack(spacing: 4) {
            button(title: "验证码登录", value: .sms, disabled: smsDisabled)
            button(title: "账号密码登录", value: .password, disabled: false)
        }
        .padding(4)
        .background(Color(hex: "F0F1F5"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func button(title: String, value: AuthLoginMode, disabled: Bool) -> some View {
        Button { onSelect(value) } label: {
            Text(title)
                .font(.system(size: 14, weight: mode == value ? .bold : .medium))
                .foregroundColor(disabled ? .themeTextSecondary.opacity(0.55) : .themeTextMain)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(mode == value ? Color.white : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .shadow(color: mode == value ? .black.opacity(0.06) : .clear, radius: 6, y: 3)
        }
    }
}

private struct AuthPage<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content
    @State private var animate = false

    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        ZStack {
            AuthMotionBackdrop(animate: animate)

            ScrollView(showsIndicators: false) {
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
                        AuthFloatingLogo()
                    }
                    .padding(.top, 54)
                    .padding(.bottom, 20)

                    content
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.easeInOut(duration: 4.8).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

private struct AuthMotionBackdrop: View {
    let animate: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [Color.white, Color(hex: "FBFBFD"), Color(hex: "F7F8FA")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Circle()
                    .fill(Color.themePrimary.opacity(0.17))
                    .frame(width: 260, height: 260)
                    .blur(radius: 34)
                    .offset(x: animate ? 170 : 110, y: animate ? -300 : -240)
                Circle()
                    .fill(Color(hex: "BFA4FF").opacity(0.14))
                    .frame(width: 320, height: 320)
                    .blur(radius: 48)
                    .offset(x: animate ? -170 : -110, y: animate ? 330 : 250)
                Circle()
                    .stroke(Color.themePrimary.opacity(0.13), lineWidth: 1.5)
                    .frame(width: 340, height: 340)
                    .offset(x: animate ? -210 : -160, y: -350)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
    }
}

private struct AuthFloatingLogo: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.themePrimary.opacity(0.25), lineWidth: 1.5)
                .frame(width: 104, height: 104)
            Circle()
                .fill(Color.white.opacity(0.56))
                .frame(width: 98, height: 98)
            Image.bundle("logo")
                .resizable()
                .scaledToFill()
                .frame(width: 82, height: 82)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 4))
        }
        .shadow(color: Color.themePrimary.opacity(0.2), radius: 16, y: 8)
    }
}

private struct AccountLaunchView: View {
    @State private var animate = false

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .stroke(Color.themePrimary.opacity(0.18), lineWidth: 2)
                    .frame(width: animate ? 160 : 112, height: animate ? 160 : 112)
                Circle()
                    .trim(from: 0.05, to: 0.72)
                    .stroke(Color.themePrimary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 132, height: 132)
                    .rotationEffect(.degrees(animate ? 360 : 0))
                Image.bundle("logo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 88, height: 88)
                    .clipShape(Circle())
            }
            Text("正在恢复你的整活现场")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.themeTextMain)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: false)) {
                animate = true
            }
        }
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
    let placeholder: String
    @State private var visible = false

    var body: some View {
        HStack(spacing: 16) {
            AuthIcon(icon: "lock")
            if visible {
                TextField(placeholder, text: $text)
            } else {
                SecureField(placeholder, text: $text)
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
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.themePrimary.opacity(0.28), radius: 12, y: 6)
        }
        .disabled(disabled)
        .opacity(disabled ? 0.62 : 1)
        .animation(.easeInOut(duration: 0.2), value: disabled)
    }
}

private extension View {
    func authFieldStyle() -> some View {
        self.frame(height: 72)
            .padding(.horizontal, 16)
            .background(Color.white.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.92), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 14, y: 6)
    }
}

private extension Error {
    var accountServerCode: String? {
        guard let authError = self as? AccountAuthError,
              case let .server(code, _) = authError else { return nil }
        return code
    }

    var requestsPasswordFallback: Bool {
        ["SMS_RATE_LIMITED", "SMS_NOT_CONFIGURED", "SMS_UPSTREAM_FAILED", "SMS_CAPACITY_LOW"].contains(accountServerCode)
    }
}
