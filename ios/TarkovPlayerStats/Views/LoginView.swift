import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @State private var authService = AuthService.shared
    @State private var errorMessage: String?

    private let tarkovGold = Color(red: 0.85, green: 0.75, blue: 0.45)

    var body: some View {
        ZStack {
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5, 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                colors: [
                    Color(red: 0.06, green: 0.06, blue: 0.04),
                    Color(red: 0.10, green: 0.08, blue: 0.05),
                    Color(red: 0.08, green: 0.08, blue: 0.06),
                    Color(red: 0.12, green: 0.10, blue: 0.06),
                    Color(red: 0.15, green: 0.12, blue: 0.08),
                    Color(red: 0.10, green: 0.10, blue: 0.08),
                    Color(red: 0.08, green: 0.06, blue: 0.04),
                    Color(red: 0.12, green: 0.12, blue: 0.10),
                    Color(red: 0.06, green: 0.06, blue: 0.05)
                ]
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    Image(systemName: "scope")
                        .font(.system(size: 72, weight: .ultraLight))
                        .foregroundStyle(tarkovGold)

                    VStack(spacing: 8) {
                        Text("ESCAPE FROM TARKOV")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(tarkovGold)
                            .tracking(3)

                        Text("Player Stats")
                            .font(.system(.largeTitle, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    Text("Track your raids, K/D ratio, survival rate,\nand skills progression.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }

                Spacer()

                VStack(spacing: 16) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = []
                    } onCompletion: { result in
                        do {
                            try authService.handleSignInResult(result)
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 52)
                    .clipShape(.rect(cornerRadius: 14))

                    Button {
                        authService.continueAsGuest()
                    } label: {
                        Text("Continue as Guest")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .padding(.horizontal, 16)
                            .adaptiveGlass(in: .rect(cornerRadius: 12))
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
        }
    }
}
