import Foundation

public enum CarbonEquivalentType: String, CaseIterable, Sendable, Codable {
    // case chickenMeal
    case chickenKg
    case eggsKg
    case beefMeal
    // case veggieMeal
    // case tapWaterLiters
    // case bottledWaterLiter
    // case heatingDayGas
    case planeKm
    // case trainKm
    case carKm
    // case smartPhone
    // case laptop
    // case computer24InchScreen
    // case tv45Inch
    case nuclearKWh
    case hydroKWh
    // case denimPants
    // case pocketBook
    // case sofa
    // case cottonTShirt
    // case a4PaperSheet
    // case houseTrashKg
    case carbonKg

    static func from(string: String) -> CarbonEquivalentType? {
        self.allCases.first { $0.rawValue == string }
    }
}

public func carbonEquivalentTypeInCarbonKg(type: CarbonEquivalentType) -> Double {
    switch type {
    case .carbonKg: return 1

    case .chickenKg: return 18.2
    case .eggsKg: return 5.3
    case .beefMeal: return 7.1428571429

    case .planeKm: return 0.146
    case .carKm: return 0.372

    case .nuclearKWh: return 0.14
    case .hydroKWh: return 0.04
    }
}

public struct CarbonEquivalent: Codable, Equatable, CustomStringConvertible {
    public var description: String { String(format: "%.2f", amount) + " " + type.rawValue }

    let type: CarbonEquivalentType
    let amount: Double

    public init(type: CarbonEquivalentType, amount: Double, comment: String? = nil) {
        self.type = type
        self.amount = amount
    }

    public init(carbonKg: Double) {
        self.type = .carbonKg
        self.amount = carbonKg
    }

    public var carbonKg: Double {
        let ratio = carbonEquivalentTypeInCarbonKg(type: self.type)
        return ratio * self.amount
    }

    public func asType(_ type: CarbonEquivalentType) -> Double {
        let invertedRatio = 1 / carbonEquivalentTypeInCarbonKg(type: type)
        return invertedRatio * self.amount
    }

    public static func == (lhs: CarbonEquivalent, rhs: CarbonEquivalent) -> Bool {
        return lhs.type == rhs.type && lhs.amount == rhs.amount
    }

    private enum CodingKeys: CodingKey {
        case type
        case amount
    }
}
