@testable import CarbonLogLib
import XCTest

final class CarbonMeasurementTests: XCTestCase {
    let date1 = calendar
        .date(from: DateComponents(year:2022, month: 1, day: 1))!
    func test_init() {
        var ms = CarbonMeasurement(kg: 0.0, at: date1)
        
        XCTAssertEqual(ms.carbonKg, 0.0)
        
        ms = CarbonMeasurement(by: CarbonEquivalent(planeKm: 2000.0), at: date1)
        XCTAssertEqual(ms.carbonKg.round(to: 2), 371.75)
        
        XCTAssertEqual(ms.description, "371.747212 at 2021-12-31 23:00:00 +0000")
    }
}
