import XCTest
@testable import CarbonLogLib

final class CarbonConverterTests: XCTestCase {
    func testEquivalent() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.

        
        var ce = CarbonEquivalent(carbonKg: 1.0)
        
        XCTAssertEqual(ce.beefMeal, 0.14)
        
        ce = CarbonEquivalent(beefMeal:  1)
        XCTAssertEqual(ce.carbonKg.round(to:2), 7.14)
        
        
        ce = CarbonEquivalent(carKm: 5.18)
        XCTAssertEqual(ce.carbonKg.round(to:2), 1.0)
    }
}

extension Double {
    func round(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
