import SwiftUI

struct ContentView: View {
    @State private var authService = AuthService.shared

    var body: some View {
        Group {
            if !authService.isSignedIn {
                LoginView()
            } else if authService.playerAccountId == nil {
                PlayerSetupView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.isSignedIn)
        .animation(.easeInOut(duration: 0.3), value: authService.playerAccountId)
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("My Profile", systemImage: "person.fill") {
                MyProfileView()
            }
            Tab("Search", systemImage: "magnifyingglass") {
                PlayerSearchView()
            }
        }
        .tint(Color(red: 0.85, green: 0.75, blue: 0.45))
    }
}
