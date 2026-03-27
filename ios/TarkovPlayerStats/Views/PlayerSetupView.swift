import SwiftUI

struct PlayerSetupView: View {
    @State private var authService = AuthService.shared
    @State private var nameInput: String = ""
    @State private var searchResults: [(id: String, name: String)] = []
    @State private var isSearching: Bool = false
    @State private var hasSearched: Bool = false
    @State private var errorMessage: String?

    private let api = TarkovAPIService.shared
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
                VStack(spacing: 12) {
                    Image(systemName: "person.text.rectangle")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(tarkovGold)

                    Text("Link Your Player")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)

                    Text("Search your Tarkov player name to link\nyour profile for quick access.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                .padding(.bottom, 32)

                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)

                        TextField("Your Tarkov player name", text: $nameInput)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.search)
                            .foregroundStyle(.white)
                            .onSubmit { searchPlayer() }

                        if !nameInput.isEmpty {
                            Button {
                                nameInput = ""
                                searchResults = []
                                hasSearched = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .adaptiveGlass(in: .rect(cornerRadius: 12))

                    Button {
                        searchPlayer()
                    } label: {
                        HStack {
                            if isSearching {
                                ProgressView()
                                    .tint(.black)
                            }
                            Text("Search")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(tarkovGold)
                        .foregroundStyle(.black)
                        .clipShape(.rect(cornerRadius: 12))
                    }
                    .disabled(nameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearching)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, 24)

                if hasSearched && searchResults.isEmpty && !isSearching {
                    VStack(spacing: 8) {
                        Image(systemName: "person.slash")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.3))
                        Text("No players found")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.top, 40)
                }

                if !searchResults.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            Text("Select your player")
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.white.opacity(0.4))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                                .padding(.bottom, 8)

                            VStack(spacing: 0) {
                                ForEach(Array(searchResults.enumerated()), id: \.element.id) { index, result in
                                    Button {
                                        authService.savePlayerName(result.name)
                                        authService.savePlayerAccountId(result.id)
                                    } label: {
                                        HStack(spacing: 14) {
                                            ZStack {
                                                Circle()
                                                    .fill(.white.opacity(0.08))
                                                    .frame(width: 40, height: 40)
                                                Image(systemName: "person.fill")
                                                    .font(.callout)
                                                    .foregroundStyle(tarkovGold)
                                            }

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(result.name)
                                                    .font(.body.weight(.medium))
                                                    .foregroundStyle(.white)
                                                Text("ID: \(result.id)")
                                                    .font(.caption)
                                                    .foregroundStyle(.white.opacity(0.3))
                                            }

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.white.opacity(0.3))
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                    }

                                    if index < searchResults.count - 1 {
                                        Divider().padding(.leading, 70)
                                    }
                                }
                            }
                            .adaptiveGlass(in: .rect(cornerRadius: 14))
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 20)
                }

                Spacer()
            }
        }
    }

    private func searchPlayer() {
        let query = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        isSearching = true
        errorMessage = nil
        hasSearched = true

        Task {
            do {
                let results = try await api.searchPlayers(name: query)
                searchResults = results
            } catch {
                errorMessage = error.localizedDescription
            }
            isSearching = false
        }
    }
}
