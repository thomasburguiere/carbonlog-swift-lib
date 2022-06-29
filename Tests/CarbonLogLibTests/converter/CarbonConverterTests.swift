import XCTest
@testable import CarbonLogLib

final class CarbonConverterTests: XCTestCase {
    func test_Equivalent() throws {
        var ce = CarbonEquivalent(carbonKg: 1.0)
        
        XCTAssertEqual(ce.beefMeal, 0.14)
        
        ce.beefMeal =  1
        XCTAssertEqual(ce.carbonKg.round(to:2), 7.14)
        
        ce = CarbonEquivalent(carKm: 5.18)
        XCTAssertEqual(ce.carbonKg.round(to:2), 1.0)
        
        ce = CarbonEquivalent(chickenKg: 0.1)
        XCTAssertEqual(ce.carbonKg.round(to:2), 1.82)
        
        
        ce = CarbonEquivalent(eggsKg: 0.1)
        XCTAssertEqual(ce.carbonKg.round(to:2), 0.53)
    }
}

extension Double {
    func round(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
