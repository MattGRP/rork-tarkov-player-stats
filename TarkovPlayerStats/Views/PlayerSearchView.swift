import SwiftUI

struct PlayerSearchView: View {
    @State private var viewModel = PlayerViewModel()
    @State private var navigateToProfile: String?

    private let tarkovGold = Color(red: 0.85, green: 0.75, blue: 0.45)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection

                    searchSection
                        .padding(.horizontal, 16)
                        .padding(.top, 24)

                    if viewModel.isSearching {
                        ProgressView()
                            .padding(.top, 40)
                    } else if viewModel.hasSearched && viewModel.searchResults.isEmpty && !viewModel.searchText.isEmpty {
                        emptyState
                            .padding(.top, 40)
                    } else if !viewModel.searchResults.isEmpty {
                        resultsSection
                            .padding(.top, 16)
                    } else {
                        placeholderSection
                            .padding(.top, 48)
                    }
                }
                .padding(.bottom, 32)
            }
            .navigationDestination(for: String.self) { accountId in
                PlayerDetailView(accountId: accountId)
            }
        }
    }

    private var headerSection: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.15, blue: 0.12), Color(red: 0.08, green: 0.08, blue: 0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 220)
            .overlay(alignment: .topTrailing) {
                Image(systemName: "scope")
                    .font(.system(size: 120, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.04))
                    .rotationEffect(.degrees(-15))
                    .offset(x: 20, y: 20)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("ESCAPE FROM TARKOV")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tarkovGold)
                    .tracking(2)

                Text("Player Lookup")
                    .font(.system(.largeTitle, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private var searchSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.body)

                    TextField("Player name or Account ID", text: $viewModel.searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit {
                            if viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).allSatisfy(\.isNumber) {
                                navigateToProfile = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                            } else {
                                viewModel.searchPlayers()
                            }
                        }

                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.searchText = ""
                            viewModel.searchResults = []
                            viewModel.hasSearched = false
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
                    if viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).allSatisfy(\.isNumber) &&
                       !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        navigateToProfile = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                    } else {
                        viewModel.searchPlayers()
                    }
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundStyle(tarkovGold)
                }
            }

            if let error = viewModel.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                }
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { navigateToProfile != nil },
            set: { if !$0 { navigateToProfile = nil } }
        )) {
            if let id = navigateToProfile {
                PlayerDetailView(accountId: id)
            }
        }
    }

    private var resultsSection: some View {
        LazyVStack(spacing: 2) {
            HStack {
                Text("\(viewModel.searchResults.count) results")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            ForEach(viewModel.searchResults, id: \.id) { result in
                NavigationLink(value: result.id) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.15, green: 0.15, blue: 0.12))
                                .frame(width: 40, height: 40)
                            Image(systemName: "person.fill")
                                .font(.callout)
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

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
            .padding(.horizontal, 16)
            .adaptiveGlass(in: .rect(cornerRadius: 14))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.slash")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text("No players found")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Try a different name or enter an Account ID directly")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }

    private var placeholderSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.text.rectangle")
                .font(.system(size: 44))
                .foregroundStyle(tarkovGold.opacity(0.5))

            VStack(spacing: 8) {
                Text("Search for a player")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Enter a player name to search the database,\nor enter an Account ID to view directly.")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 16) {
                statHint(icon: "scope", label: "K/D Ratio")
                statHint(icon: "chart.bar.fill", label: "Survival Rate")
                statHint(icon: "star.fill", label: "Skills")
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 32)
    }

    private func statHint(icon: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tarkovGold.opacity(0.6))
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .adaptiveGlass(in: .rect(cornerRadius: 12))
    }
}
