import Foundation

public struct CarbonMeasurement: CustomStringConvertible, Codable {
    public var description: String {
        let formatter = ISO8601DateFormatter()
        return String(format: "%.2f", self.carbonKg.round(to: 2)) + " at " + formatter.string(from: self.date)
    }

    public let date: Date
    public let carbonKg: Double
    public let comment: String?

    public init(kg: Double, at date: Date, comment: String? = nil) {
        self.carbonKg = kg
        self.date = date
        self.comment = comment
    }

    public init(kg: Double) {
        self.init(kg: kg, at: Date())
    }

    public init(by carbonEq: CarbonEquivalent) {
        self.init(by: carbonEq, at: Date(), comment: carbonEq.description)
    }

    public init(by carbonEq: CarbonEquivalent, at date: Date, comment: String? = nil) {
        let kg = carbonEq.carbonKg
        guard let comment else {
            self.init(kg: kg, at: date, comment: carbonEq.description)
            return
        }
        self.init(kg: kg, at: date, comment: comment)

    }

    public var equivalent: CarbonEquivalent { CarbonEquivalent(carbonKg: self.carbonKg) }
}

extension Double {
    func round(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
