import SwiftUI

struct PlayerDetailView: View {
    let accountId: String
    @State private var viewModel = PlayerViewModel()

    private let tarkovGold = Color(red: 0.85, green: 0.75, blue: 0.45)

    var body: some View {
        Group {
            if viewModel.isLoadingProfile {
                loadingView
            } else if let profile = viewModel.selectedProfile {
                profileContent(profile)
            } else if let error = viewModel.errorMessage {
                errorView(error)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadProfile(accountId: accountId)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Loading profile…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            Text("Failed to load profile")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await viewModel.loadProfile(accountId: accountId) }
            }
            .buttonStyle(.borderedProminent)
            .tint(tarkovGold)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func profileContent(_ profile: PlayerProfile) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                playerHeader(profile)
                statsOverview
                    .padding(.top, 20)
                    .padding(.horizontal, 16)
                pmcStatsSection
                    .padding(.top, 24)
                    .padding(.horizontal, 16)
                loadoutSection
                    .padding(.top, 24)
                    .padding(.horizontal, 16)
                skillsSection
                    .padding(.top, 24)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
            }
        }
    }

    private func playerHeader(_ profile: PlayerProfile) -> some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    profile.info.side == "Bear"
                        ? Color(red: 0.55, green: 0.15, blue: 0.12)
                        : Color(red: 0.12, green: 0.20, blue: 0.40),
                    Color(red: 0.08, green: 0.08, blue: 0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 280)
            .overlay(alignment: .trailing) {
                CharacterImageView(profile: profile, height: 260)
                    .offset(x: 40)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile.info.nickname)
                            .font(.title.weight(.bold))
                            .foregroundStyle(.white)

                        HStack(spacing: 8) {
                            factionBadge(profile.info.side)
                            levelBadge(viewModel.playerLevel)
                        }
                    }
                }

                HStack(spacing: 16) {
                    headerStat(label: "XP", value: formatNumber(profile.info.experience))
                    headerStat(label: "Account ID", value: "\(profile.aid)")
                    if let prestige = profile.info.prestigeLevel, prestige > 0 {
                        headerStat(label: "Prestige", value: "\(prestige)")
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private var statsOverview: some View {
        let pmc = viewModel.pmcStats ?? PlayerStats(sessions: 0, survived: 0, kills: 0, deaths: 0, totalInGameTime: 0)

        return LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            statCard(value: String(format: "%.2f", pmc.kd), label: "K/D", icon: "scope", color: .red)
            statCard(value: String(format: "%.0f%%", pmc.survivalRate), label: "Survival", icon: "heart.fill", color: .green)
            statCard(value: "\(pmc.kills)", label: "Kills", icon: "flame.fill", color: .orange)
            statCard(value: "\(pmc.sessions)", label: "Raids", icon: "map.fill", color: .blue)
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .adaptiveGlass(in: .rect(cornerRadius: 14))
    }

    private var pmcStatsSection: some View {
        let pmc = viewModel.pmcStats ?? PlayerStats(sessions: 0, survived: 0, kills: 0, deaths: 0, totalInGameTime: 0)

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(tarkovGold)
                Text("PMC Statistics")
                    .font(.headline)
            }

            VStack(spacing: 0) {
                statsRow(label: "Total Raids", value: "\(pmc.sessions)")
                Divider().padding(.leading, 16)
                statsRow(label: "Survived", value: "\(pmc.survived)")
                Divider().padding(.leading, 16)
                statsRow(label: "Kills", value: "\(pmc.kills)")
                Divider().padding(.leading, 16)
                statsRow(label: "Deaths", value: "\(pmc.deaths)")
                Divider().padding(.leading, 16)
                statsRow(label: "K/D Ratio", value: String(format: "%.2f", pmc.kd))
                Divider().padding(.leading, 16)
                statsRow(label: "Survival Rate", value: String(format: "%.1f%%", pmc.survivalRate))
                Divider().padding(.leading, 16)
                statsRow(label: "Time in Raids", value: formatPlaytime(pmc.totalInGameTime))
            }
            .adaptiveGlass(in: .rect(cornerRadius: 14))
        }
    }

    private var loadoutSection: some View {
        LoadoutSectionView(equippedItems: viewModel.equippedItems)
    }

    private var skillsSection: some View {
        let skills = viewModel.filteredSkills

        return Group {
            if !skills.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundStyle(tarkovGold)
                        Text("Skills")
                            .font(.headline)
                    }

                    VStack(spacing: 0) {
                        ForEach(Array(skills.enumerated()), id: \.element.id) { index, skill in
                            skillRow(skill)
                            if index < skills.count - 1 {
                                Divider().padding(.leading, 16)
                            }
                        }
                    }
                    .adaptiveGlass(in: .rect(cornerRadius: 14))
                }
            }
        }
    }

    private func statsRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func skillRow(_ skill: SkillEntry) -> some View {
        let level = Int(skill.Progress / 100)
        let progress = (skill.Progress.truncatingRemainder(dividingBy: 100)) / 100.0

        return HStack(spacing: 12) {
            Image(systemName: skillIcon(skill.Id))
                .font(.callout)
                .foregroundStyle(skillColor(skill.Id))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(formatSkillName(skill.Id))
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text("Lvl \(level)")
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.tertiarySystemBackground))
                            .frame(height: 4)
                        Capsule()
                            .fill(skillColor(skill.Id))
                            .frame(width: geo.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func factionBadge(_ side: String) -> some View {
        Text(side.uppercased())
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .adaptiveGlassTinted(
                side == "Bear"
                    ? Color(red: 0.7, green: 0.2, blue: 0.15)
                    : Color(red: 0.15, green: 0.3, blue: 0.6),
                in: .rect(cornerRadius: 6)
            )
    }

    private func levelBadge(_ level: Int) -> some View {
        Text("LVL \(level)")
            .font(.caption2.weight(.bold).monospacedDigit())
            .foregroundStyle(tarkovGold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .adaptiveGlass(in: .rect(cornerRadius: 6))
    }

    private func headerStat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private func factionIcon(_ side: String) -> String {
        side == "Bear" ? "pawprint.fill" : "shield.checkered"
    }

    private func formatNumber(_ n: Int) -> String {
        if n >= 1_000_000 {
            return String(format: "%.1fM", Double(n) / 1_000_000)
        } else if n >= 1_000 {
            return String(format: "%.1fK", Double(n) / 1_000)
        }
        return "\(n)"
    }

    private func formatPlaytime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private func formatSkillName(_ id: String) -> String {
        var result = ""
        for char in id {
            if char.isUppercase && !result.isEmpty {
                result += " "
            }
            result.append(char)
        }
        return result
    }

    private func skillIcon(_ id: String) -> String {
        switch id {
        case "Endurance": return "figure.run"
        case "Strength": return "dumbbell.fill"
        case "Vitality": return "heart.fill"
        case "Health": return "cross.fill"
        case "StressResistance": return "brain.head.profile"
        case "Metabolism": return "fork.knife"
        case "Immunity": return "shield.fill"
        case "Perception": return "eye.fill"
        case "Attention": return "exclamationmark.circle.fill"
        case "Charisma": return "person.wave.2.fill"
        case "CovertMovement": return "figure.walk"
        case "Search": return "magnifyingglass"
        case "Surgery": return "bandage.fill"
        case "AimDrills": return "target"
        case "TroubleShooting": return "wrench.and.screwdriver.fill"
        case "Throwing": return "hand.point.up.fill"
        case "Melee": return "hammer.fill"
        default:
            if ["Pistol", "Revolver", "SMG", "Assault", "Shotgun", "Sniper", "LMG", "HMG", "DMR", "Launcher", "AttachedLauncher"].contains(id) {
                return "scope"
            }
            return "star.fill"
        }
    }

    private func skillColor(_ id: String) -> Color {
        switch id {
        case "Endurance", "Strength", "CovertMovement": return .blue
        case "Vitality", "Health", "Immunity", "Surgery": return .red
        case "StressResistance": return .purple
        case "Metabolism": return .green
        case "Perception", "Attention", "Search": return .cyan
        case "Charisma": return .pink
        case "AimDrills", "TroubleShooting": return .orange
        default: return tarkovGold
        }
    }
}
