import Foundation

nonisolated struct PlayerProfile: Codable, Sendable {
    let aid: Int
    let info: PlayerInfo
    let customization: PlayerCustomization
    let skills: PlayerSkills?
    let equipment: EquipmentContainer?
    let pmcStats: GameStats?
    let scavStats: GameStats?
    let achievements: [String: Int]?
    let updated: Int?

    var characterImageURL: URL? {
        var components = URLComponents(string: "https://imagemagic.tarkov.dev/player/\(aid).webp")
        let dataDict: [String: Any] = [
            "aid": aid,
            "customization": [
                "head": customization.head ?? "",
                "body": customization.body ?? "",
                "feet": customization.feet ?? "",
                "hands": customization.hands ?? ""
            ],
            "equipment": [
                "Id": equipment?.Id ?? "",
                "Items": (equipment?.Items ?? []).map { item -> [String: Any] in
                    var dict: [String: Any] = [
                        "_id": item._id,
                        "_tpl": item._tpl
                    ]
                    if let parentId = item.parentId { dict["parentId"] = parentId }
                    if let slotId = item.slotId { dict["slotId"] = slotId }
                    return dict
                }
            ]
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: dataDict),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            components?.queryItems = [URLQueryItem(name: "data", value: jsonString)]
        }
        return components?.url
    }
}

nonisolated struct PlayerInfo: Codable, Sendable {
    let nickname: String
    let side: String
    let experience: Int
    let memberCategory: Int?
    let selectedMemberCategory: Int?
    let prestigeLevel: Int?
}

nonisolated struct PlayerCustomization: Codable, Sendable {
    let head: String?
    let body: String?
    let feet: String?
    let hands: String?
}

nonisolated struct EquipmentContainer: Codable, Sendable {
    let Id: String
    let Items: [EquipmentItem]
}

nonisolated struct EquipmentItem: Codable, Sendable, Identifiable {
    nonisolated var id: String { _id }
    let _id: String
    let _tpl: String
    let parentId: String?
    let slotId: String?
    let upd: ItemUpdate?

    static let mainSlots: [String] = [
        "Headwear", "Earpiece", "FaceCover", "Eyewear",
        "ArmorVest", "TacticalVest", "ArmBand",
        "FirstPrimaryWeapon", "SecondPrimaryWeapon", "Holster",
        "Backpack", "SecuredContainer", "Scabbard"
    ]

    static func slotDisplayName(_ slot: String) -> String {
        switch slot {
        case "FirstPrimaryWeapon": return "Primary"
        case "SecondPrimaryWeapon": return "Secondary"
        case "Holster": return "Sidearm"
        case "ArmorVest": return "Armor"
        case "TacticalVest": return "Rig"
        case "FaceCover": return "Face Cover"
        case "SecuredContainer": return "Secure"
        case "ArmBand": return "Armband"
        default: return slot
        }
    }

    static func slotIcon(_ slot: String) -> String {
        switch slot {
        case "Headwear": return "helmet.fill"
        case "Earpiece": return "headphones"
        case "FaceCover": return "theatermask.and.paintbrush.fill"
        case "Eyewear": return "eyeglasses"
        case "ArmorVest": return "shield.lefthalf.filled"
        case "TacticalVest": return "tshirt.fill"
        case "ArmBand": return "bandage.fill"
        case "FirstPrimaryWeapon": return "scope"
        case "SecondPrimaryWeapon": return "scope"
        case "Holster": return "target"
        case "Backpack": return "bag.fill"
        case "SecuredContainer": return "lock.fill"
        case "Scabbard": return "hammer.fill"
        default: return "square.fill"
        }
    }

    var itemImageURL: URL? {
        URL(string: "https://assets.tarkov.dev/\(_tpl)-icon.webp")
    }
}

nonisolated struct ItemUpdate: Codable, Sendable {
    let StackObjectsCount: Int?
    let Repairable: RepairableState?
}

nonisolated struct RepairableState: Codable, Sendable {
    let Durability: Double?
    let MaxDurability: Double?
}

nonisolated struct PlayerSkills: Codable, Sendable {
    let Common: [SkillEntry]?
    let Mastering: [MasteringEntry]?
    let Points: Double?
}

nonisolated struct SkillEntry: Codable, Sendable, Identifiable {
    nonisolated var id: String { Id }
    let Id: String
    let Progress: Double
    let PointsEarnedDuringSession: Double?
    let LastAccess: Int?
}

nonisolated struct MasteringEntry: Codable, Sendable, Identifiable {
    nonisolated var id: String { Id }
    let Id: String
    let Progress: Int?
}

nonisolated struct GameStats: Codable, Sendable {
    let eft: EFTStats?
}

nonisolated struct EFTStats: Codable, Sendable {
    let totalInGameTime: Int?
    let overAllCounters: OverAllCounters?
}

nonisolated struct OverAllCounters: Codable, Sendable {
    let Items: [CounterItem]?
}

nonisolated struct CounterItem: Codable, Sendable {
    let Key: [String]
    let Value: Int
}

struct PlayerStats {
    let sessions: Int
    let survived: Int
    let kills: Int
    let deaths: Int
    let totalInGameTime: Int

    var kd: Double {
        deaths == 0 ? Double(kills) : Double(kills) / Double(deaths)
    }

    var survivalRate: Double {
        sessions == 0 ? 0 : Double(survived) / Double(sessions) * 100
    }

    var avgSessionTime: TimeInterval {
        sessions == 0 ? 0 : Double(totalInGameTime) / Double(sessions)
    }

    static func from(gameStats: GameStats?) -> PlayerStats {
        let counters = gameStats?.eft?.overAllCounters?.Items ?? []
        let totalTime = gameStats?.eft?.totalInGameTime ?? 0

        var sessions = 0
        var survived = 0
        var kills = 0
        var deaths = 0

        for item in counters {
            let key = item.Key
            if key.first == "Sessions" {
                sessions += item.Value
            } else if key.first == "ExitStatus" && key.contains("Survived") {
                survived += item.Value
            } else if key == ["Kills"] {
                kills = item.Value
            } else if key == ["Deaths"] {
                deaths = item.Value
            }
        }

        return PlayerStats(
            sessions: sessions,
            survived: survived,
            kills: kills,
            deaths: deaths,
            totalInGameTime: totalTime
        )
    }
}

nonisolated enum ExperienceLevel: Sendable {
    static let thresholds: [Int] = [
        0, 1000, 4017, 8432, 14256, 21477, 30023, 39936, 51204, 63723,
        77563, 92713, 110144, 128384, 149867, 172144, 197203, 225938, 259311, 295287,
        336008, 382308, 432768, 490936, 557528, 631688, 714168, 804808, 905408, 1018908,
        1141108, 1272508, 1413908, 1570708, 1742908, 1930508, 2133508, 2351908, 2585708, 2834908,
        3099508, 3379508, 3674908, 3985708, 4311908, 4653508, 5010508, 5382908, 5770708, 6173908,
        6592508, 7026508, 7475908, 7940708, 8420908, 8916508, 9427508, 9953908, 10495708, 11052908,
        11625508, 12213508, 12816908, 13435708, 14069908, 14719508, 15384508, 16064908, 16760708, 17471908
    ]

    static func level(for experience: Int) -> Int {
        var lvl = 1
        for (i, xp) in thresholds.enumerated() {
            if experience >= xp {
                lvl = i + 1
            } else {
                break
            }
        }
        return lvl
    }
}
