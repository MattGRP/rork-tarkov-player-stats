import Foundation

@Observable
final class PlayerViewModel {
    var searchText: String = ""
    var searchResults: [(id: String, name: String)] = []
    var selectedProfile: PlayerProfile?
    var isSearching: Bool = false
    var isLoadingProfile: Bool = false
    var errorMessage: String?
    var hasSearched: Bool = false

    private let api = TarkovAPIService.shared
    private var searchTask: Task<Void, Never>?

    var pmcStats: PlayerStats? {
        guard let profile = selectedProfile else { return nil }
        return PlayerStats.from(gameStats: profile.pmcStats)
    }

    var scavStats: PlayerStats? {
        guard let profile = selectedProfile else { return nil }
        return PlayerStats.from(gameStats: profile.scavStats)
    }

    var playerLevel: Int {
        guard let profile = selectedProfile else { return 0 }
        return ExperienceLevel.level(for: profile.info.experience)
    }

    var filteredSkills: [SkillEntry] {
        guard let skills = selectedProfile?.skills?.Common else { return [] }
        return skills
            .filter { $0.Progress > 0 && !$0.Id.hasPrefix("Bot") }
            .sorted { $0.Progress > $1.Progress }
    }

    var equippedItems: [String: EquipmentItem] {
        guard let items = selectedProfile?.equipment?.Items else { return [:] }
        var slotMap: [String: EquipmentItem] = [:]
        for item in items {
            if let slot = item.slotId, EquipmentItem.mainSlots.contains(slot) {
                slotMap[slot] = item
            }
        }
        return slotMap
    }

    func searchPlayers() {
        searchTask?.cancel()
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            searchResults = []
            hasSearched = false
            return
        }

        searchTask = Task {
            isSearching = true
            errorMessage = nil
            hasSearched = true

            do {
                try await Task.sleep(for: .milliseconds(300))
                let results = try await api.searchPlayers(name: query)
                if !Task.isCancelled {
                    searchResults = results
                }
            } catch is CancellationError {
            } catch {
                if !Task.isCancelled {
                    errorMessage = error.localizedDescription
                }
            }

            if !Task.isCancelled {
                isSearching = false
            }
        }
    }

    func loadProfile(accountId: String) async {
        isLoadingProfile = true
        errorMessage = nil

        do {
            selectedProfile = try await api.fetchPlayerProfile(accountId: accountId)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingProfile = false
    }

    func loadProfileById() async {
        let id = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return }

        if id.allSatisfy(\.isNumber) {
            await loadProfile(accountId: id)
        }
    }
}
