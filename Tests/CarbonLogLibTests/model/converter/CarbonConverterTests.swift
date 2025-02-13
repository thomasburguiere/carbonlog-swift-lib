import Foundation
import Testing

@testable import CarbonLogLib

struct CarbonConverterTests {
    @Test func test_Equivalent() throws {
        var ce = CarbonEquivalent(carbonKg: 1.0)

        #expect(ce.beefMeal == 0.14)

        ce.beefMeal = 1
        #expect(ce.carbonKg.round(to: 2) == 7.14)

        ce = CarbonEquivalent(carKm: 5.18)
        #expect(ce.carbonKg.round(to: 2) == 1.0)

        ce = CarbonEquivalent(chickenKg: 0.1)
        #expect(ce.carbonKg.round(to: 2) == 1.82)

        ce = CarbonEquivalent(eggsKg: 0.1)
        #expect(ce.carbonKg.round(to: 2) == 0.53)

        ce = CarbonEquivalent(nuclearKWh: 100)
        #expect(ce.carbonKg.round(to: 2) == 14)

        ce = CarbonEquivalent(hydroKWh: 100)
        #expect(ce.carbonKg.round(to: 2) == 4)
    }
}

extension Double {
    func round(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
