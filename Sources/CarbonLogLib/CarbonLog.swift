
import Foundation

fileprivate let cal: Calendar = Calendar(identifier: .gregorian)

public struct CarbonLog {
    
    public let measurements: Array<CarbonMeasurement>
    
    public init() {
        self.measurements = Array()
    }
    
    public init(with measurements: Array<CarbonMeasurement>) {
        self.measurements = measurements
    }
    
    public func getRangeCarbonKgs(from:Date, to:Date = Date(), inclusive: Bool = false) -> Double {
        
        let filter: (CarbonMeasurement) -> Bool
        if (!inclusive) {
            filter = { (cm: CarbonMeasurement) -> Bool in
                cm.date.compare(from).rawValue > 0 && cm.date.compare(to).rawValue < 0
            }
        } else {
            filter = { (cm: CarbonMeasurement) -> Bool in
                cm.date.compare(from).rawValue >= 0 && cm.date.compare(to).rawValue <= 0
            }
        }
        
        return measurements
            .filter(filter)
            .map{ $0.carbonKg }
            .reduce(0.0) { acc, next in
                acc + next
            }
    }
    
    public func getCurrentYearCarbonKgs() -> Double {
        let currentYear = cal.component(Calendar.Component.year, from: Date())
        
        return measurements
            .filter{ m in
                let measurementYear = cal.component(Calendar.Component.year, from: m.date)
                return measurementYear == currentYear
            }
            .map {$0.carbonKg}
            .reduce(0.0) { acc, next in
                acc + next
            }
    }
    
    public func add(measurements: Array<CarbonMeasurement>) -> CarbonLog {
        return CarbonLog(with: self.measurements + measurements)
    }
}
