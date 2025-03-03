import Foundation

private let cal: Calendar = .init(identifier: .gregorian)

public struct CarbonLog: Codable, Sendable {
    public let measurements: [CarbonMeasurement]
    public let id: String

    public init(id: String) {
        self.init(with: [], id: id)
    }

    public init(with measurements: [CarbonMeasurement], id: String) {
        self.measurements = measurements
        self.id = id
    }

    public func getRangeCarbonKgs(
        from: Date,
        to: Date = Date(),
        inclusive: Bool = false
    ) -> Double {
        let filter: (CarbonMeasurement) -> Bool
        if !inclusive {
            filter = { (cm: CarbonMeasurement) -> Bool in
                cm.date.compare(from).rawValue > 0 && cm.date.compare(to).rawValue < 0
            }
        } else {
            filter = { (cm: CarbonMeasurement) -> Bool in
                cm.date.compare(from).rawValue >= 0 && cm.date.compare(to).rawValue <= 0
            }
        }

        return
            measurements
                .filter(filter)
                .map { $0.carbonKg }
                .reduce(0.0) { $0 + $1 }
    }

    public func getCurrentYearCarbonKgs() -> Double {
        let currentYear = cal.component(.year, from: Date())

        return
            measurements
                .filter { cal.component(.year, from: $0.date) == currentYear }
                .map { $0.carbonKg }
                .reduce(0.0) { $0 + $1 }
    }

    public func add(measurements: [CarbonMeasurement]) -> CarbonLog {
        return CarbonLog(with: self.measurements + measurements, id: id)
    }
}
