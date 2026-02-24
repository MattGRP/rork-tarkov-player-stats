import SwiftUI

struct LoadoutSectionView: View {
    let equippedItems: [String: EquipmentItem]

    private let tarkovGold = Color(red: 0.85, green: 0.75, blue: 0.45)

    private let weaponSlots = ["FirstPrimaryWeapon", "SecondPrimaryWeapon", "Holster", "Scabbard"]
    private let gearSlots = ["ArmorVest", "TacticalVest", "Backpack", "SecuredContainer"]
    private let headSlots = ["Headwear", "Earpiece", "FaceCover", "Eyewear"]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "backpack.fill")
                    .foregroundStyle(tarkovGold)
                Text("Loadout")
                    .font(.headline)
            }

            if equippedItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "xmark.shield")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("No loadout data available")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .adaptiveGlass(in: .rect(cornerRadius: 14))
            } else {
                slotGroup(title: "Weapons", slots: weaponSlots, icon: "scope")
                slotGroup(title: "Gear", slots: gearSlots, icon: "shield.lefthalf.filled")
                slotGroup(title: "Head", slots: headSlots, icon: "helmet.fill")

                if let armband = equippedItems["ArmBand"] {
                    singleSlotCard(slot: "ArmBand", item: armband)
                }
            }
        }
    }

    private func slotGroup(title: String, slots: [String], icon: String) -> some View {
        let activeSlots = slots.filter { equippedItems[$0] != nil }
        return Group {
            if !activeSlots.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(activeSlots.enumerated()), id: \.element) { index, slot in
                        if let item = equippedItems[slot] {
                            equipmentRow(slot: slot, item: item)
                            if index < activeSlots.count - 1 {
                                Divider().padding(.leading, 72)
                            }
                        }
                    }
                }
                .adaptiveGlass(in: .rect(cornerRadius: 14))
            }
        }
    }

    private func singleSlotCard(slot: String, item: EquipmentItem) -> some View {
        VStack(spacing: 0) {
            equipmentRow(slot: slot, item: item)
        }
        .adaptiveGlass(in: .rect(cornerRadius: 14))
    }

    private func equipmentRow(slot: String, item: EquipmentItem) -> some View {
        HStack(spacing: 12) {
            Color(.secondarySystemBackground)
                .frame(width: 48, height: 48)
                .overlay {
                    AsyncImage(url: item.itemImageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(4)
                        case .failure:
                            Image(systemName: EquipmentItem.slotIcon(slot))
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        default:
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                    .allowsHitTesting(false)
                }
                .clipShape(.rect(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(EquipmentItem.slotDisplayName(slot))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Text(formatItemId(item._tpl))
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                if let rep = item.upd?.Repairable,
                   let dur = rep.Durability,
                   let maxDur = rep.MaxDurability,
                   maxDur > 0 {
                    durabilityBar(current: dur, max: maxDur)
                }
            }

            Spacer()

            Image(systemName: EquipmentItem.slotIcon(slot))
                .font(.caption)
                .foregroundStyle(tarkovGold.opacity(0.6))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func durabilityBar(current: Double, max: Double) -> some View {
        let ratio = max > 0 ? current / max : 0
        let color: Color = ratio > 0.6 ? .green : ratio > 0.3 ? .orange : .red

        return HStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.tertiarySystemBackground))
                        .frame(height: 3)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * ratio, height: 3)
                }
            }
            .frame(width: 60, height: 3)

            Text("\(Int(current))/\(Int(max))")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private func formatItemId(_ tpl: String) -> String {
        let short = String(tpl.suffix(8))
        return "Item \(short)"
    }
}

struct CharacterImageView: View {
    let profile: PlayerProfile
    let height: CGFloat

    var body: some View {
        Color.clear
            .frame(height: height)
            .overlay {
                AsyncImage(url: profile.characterImageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.white.opacity(0.3))
                    default:
                        ProgressView()
                            .controlSize(.regular)
                            .tint(.white.opacity(0.5))
                    }
                }
                .allowsHitTesting(false)
            }
    }
}
