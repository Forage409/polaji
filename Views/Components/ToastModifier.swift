import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let duration: TimeInterval
    @State private var dismissTask: Task<Void, Never>?
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if isPresented {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "E8AF16"))
                    Text(message)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.themeTextMain)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .background(.ultraThinMaterial)
                .background(Color.white.opacity(0.78))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.9), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.13), radius: 18, y: 8)
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .top)
                            .combined(with: .opacity)
                            .combined(with: .scale(scale: 0.92, anchor: .top)),
                        removal: .move(edge: .top)
                            .combined(with: .opacity)
                            .combined(with: .scale(scale: 0.96, anchor: .top))
                    )
                )
                .zIndex(9999)
                .onAppear {
                    dismissTask?.cancel()
                    dismissTask = Task {
                        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                        guard !Task.isCancelled else { return }
                        await MainActor.run {
                            withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
                                isPresented = false
                            }
                        }
                    }
                }
                .onDisappear {
                    dismissTask?.cancel()
                }
            }
        }
        .animation(.spring(response: 0.48, dampingFraction: 0.82), value: isPresented)
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: String, duration: TimeInterval = 2.0) -> some View {
        self.modifier(ToastModifier(isPresented: isPresented, message: message, duration: duration))
    }
}
