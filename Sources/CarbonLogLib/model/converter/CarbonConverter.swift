public enum CarbonEqType: String, CaseIterable, Sendable {
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

    static func from(string: String) -> CarbonEqType? {
        self.allCases.first { $0.rawValue == string }
    }
}

public func carbonEqTypeInCarbonKg(type: CarbonEqType) -> Double {
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

public struct CarbonEquivalent {
    let type: CarbonEqType
    let amount: Double

    public init(type: CarbonEqType, amount: Double) {
        self.type = type
        self.amount = amount
    }

    public init(carbonKg: Double) {
        self.type = .carbonKg
        self.amount = carbonKg
    }

    public var carbonKg: Double {
        let ratio = carbonEqTypeInCarbonKg(type: self.type)
        return ratio * self.amount
    }

    public func asType(_ type: CarbonEqType) -> Double {
        let invertedRatio = 1 / carbonEqTypeInCarbonKg(type: type)
        return invertedRatio * self.amount
    }
}
