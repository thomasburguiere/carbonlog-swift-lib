import Foundation

public struct CarbonMeasurement: CustomStringConvertible, Codable {
    public var description: String {
        let formatter = ISO8601DateFormatter()
        return String(format: "%f", self.carbonKg) + " at " + formatter.string(from: self.date)
    }

    public let date: Date
    public let carbonKg: Double
    public let comment: String?

    public init(kg: Double, at date: Date) {
        self.carbonKg = kg
        self.date = date
        self.comment = nil
    }

    public init(kg: Double) {
        self.init(kg: kg, at: Date())
    }

    public init(by carbonEq: CarbonEquivalent) {
        self.init(by: carbonEq, at: Date())
    }

    public init(by carbonEq: CarbonEquivalent, at date: Date) {
        self.init(kg: carbonEq.carbonKg, at: date)
    }

    public var equivalent: CarbonEquivalent { CarbonEquivalent(carbonKg: self.carbonKg) }
}
