import Foundation

public struct CarbonMeasurement {
    
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
        self.carbonKg = carbonEq.carbonKg
        self.date = Date()
    }
    
    public var equivalent: CarbonEquivalent { CarbonEquivalent(carbonKg: self.carbonKg)}
    
}
