@testable import CarbonLogLib
import XCTest

final class CarbonMeasurementTests: XCTestCase {
    
    func test_init() {
        var ms = CarbonMeasurement(carbonKg: 0.0)
        
        XCTAssertEqual(ms.carbonKg, 0.0)
        
        ms = CarbonMeasurement(by: CarbonEquivalent(planeKm: 2000.0))
        XCTAssertEqual(ms.carbonKg.round(to: 2), 371.75)
    }
}
