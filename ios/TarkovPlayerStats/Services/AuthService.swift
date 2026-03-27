import Foundation
import AuthenticationServices

@Observable
final class AuthService {
    static let shared = AuthService()

    var isSignedIn: Bool = false
    var userID: String?
    var playerName: String?
    var playerAccountId: String?

    private let userIDKey = "appleUserID"
    private let playerNameKey = "tarkovPlayerName"
    private let playerAccountIdKey = "tarkovPlayerAccountId"

    private init() {
        loadStoredUser()
    }

    private func loadStoredUser() {
        let storedUserID = UserDefaults.standard.string(forKey: userIDKey)
        if let storedUserID, !storedUserID.isEmpty {
            userID = storedUserID
            playerName = UserDefaults.standard.string(forKey: playerNameKey)
            playerAccountId = UserDefaults.standard.string(forKey: playerAccountIdKey)
            isSignedIn = true
        }
    }

    func handleSignInResult(_ result: Result<ASAuthorization, Error>) throws {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw AuthError.invalidCredential
            }
            let uid = credential.user
            UserDefaults.standard.set(uid, forKey: userIDKey)
            userID = uid
            isSignedIn = true

        case .failure(let error):
            throw error
        }
    }

    func savePlayerName(_ name: String) {
        playerName = name
        UserDefaults.standard.set(name, forKey: playerNameKey)
    }

    func savePlayerAccountId(_ id: String) {
        playerAccountId = id
        UserDefaults.standard.set(id, forKey: playerAccountIdKey)
    }

    func continueAsGuest() {
        let guestID = "guest_\(UUID().uuidString)"
        UserDefaults.standard.set(guestID, forKey: userIDKey)
        userID = guestID
        isSignedIn = true
    }

    func signOut() {
        UserDefaults.standard.removeObject(forKey: userIDKey)
        UserDefaults.standard.removeObject(forKey: playerNameKey)
        UserDefaults.standard.removeObject(forKey: playerAccountIdKey)
        userID = nil
        playerName = nil
        playerAccountId = nil
        isSignedIn = false
    }
}

nonisolated enum AuthError: Error, LocalizedError, Sendable {
    case invalidCredential
    case signInFailed(String)

    nonisolated var errorDescription: String? {
        switch self {
        case .invalidCredential: return "Invalid credential received"
        case .signInFailed(let msg): return msg
        }
    }
}
