import SwiftUI

struct ChangePlayerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var authService = AuthService.shared
    @State private var nameInput: String = ""
    @State private var searchResults: [(id: String, name: String)] = []
    @State private var isSearching: Bool = false
    @State private var hasSearched: Bool = false
    @State private var errorMessage: String?

    private let api = TarkovAPIService.shared
    private let tarkovGold = Color(red: 0.85, green: 0.75, blue: 0.45)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let currentName = authService.playerName {
                    HStack(spacing: 12) {
                        Image(systemName: "person.fill")
                            .foregroundStyle(tarkovGold)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Current Player")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(currentName)
                                .font(.body.weight(.medium))
                        }
                        Spacer()
                    }
                    .padding(16)
                    .adaptiveGlass(in: .rect(cornerRadius: 12))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }

                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)

                        TextField("Search new player name", text: $nameInput)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.search)
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
                                    .tint(.white)
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
                .padding(.horizontal, 16)
                .padding(.top, 20)

                if hasSearched && searchResults.isEmpty && !isSearching {
                    VStack(spacing: 8) {
                        Image(systemName: "person.slash")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                        Text("No players found")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)
                }

                if !searchResults.isEmpty {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(searchResults.enumerated()), id: \.element.id) { index, result in
                                Button {
                                    authService.savePlayerName(result.name)
                                    authService.savePlayerAccountId(result.id)
                                    dismiss()
                                } label: {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            Circle()
                                                .fill(Color(red: 0.15, green: 0.15, blue: 0.12))
                                                .frame(width: 36, height: 36)
                                            Image(systemName: "person.fill")
                                                .font(.caption)
                                                .foregroundStyle(tarkovGold)
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(result.name)
                                                .font(.body.weight(.medium))
                                                .foregroundStyle(.primary)
                                            Text("ID: \(result.id)")
                                                .font(.caption)
                                                .foregroundStyle(.tertiary)
                                        }

                                        Spacer()

                                        Image(systemName: "checkmark.circle")
                                            .foregroundStyle(tarkovGold)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }

                                if index < searchResults.count - 1 {
                                    Divider().padding(.leading, 66)
                                }
                            }
                        }
                        .adaptiveGlass(in: .rect(cornerRadius: 14))
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 16)
                }

                Spacer()
            }
            .navigationTitle("Change Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
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
