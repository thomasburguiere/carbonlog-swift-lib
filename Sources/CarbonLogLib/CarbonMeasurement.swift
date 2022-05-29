import Foundation

public class CarbonMeasurement {
    
    public let date = Date()
    public let carbonKg: Double
    
    public init(carbonKg: Double) {
        self.carbonKg = carbonKg
    }
    
    public init(by carbonEq: CarbonEquivalent) {
        self.carbonKg = carbonEq.carbonKg
    }
    
    public var equivalent: CarbonEquivalent { CarbonEquivalent(carbonKg: self.carbonKg)}
    
}
