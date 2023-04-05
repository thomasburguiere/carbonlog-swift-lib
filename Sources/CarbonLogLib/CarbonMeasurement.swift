import Foundation

public struct CarbonMeasurement: CustomStringConvertible {
    public var description: String { return String(format: "%f", self.carbonKg) + " at " + self.date.description }

    public let date: Date
    public let carbonKg: Double

    public init(carbonKg: Double) {
        self.carbonKg = carbonKg
        self.date = Date()
    }

    public init(kg carbonKg: Double, at date: Date) {
        self.carbonKg = carbonKg
        self.date = date
    }

    public init(by carbonEq: CarbonEquivalent) {
        self.init(by: carbonEq, at: Date())
    }

    public init(by carbonEq: CarbonEquivalent, at date: Date) {
        self.carbonKg = carbonEq.carbonKg
        self.date = date
    }

    public var equivalent: CarbonEquivalent { CarbonEquivalent(carbonKg: self.carbonKg) }

}
