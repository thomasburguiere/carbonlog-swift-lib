import XCTest

@testable import CarbonLogLib

final class CarbonMeasurementTests: XCTestCase {
    let date1 =
        calendar
        .date(from: DateComponents(year: 2022, month: 4, day: 6, hour: 12))!
    func test_init() {
        var ms = CarbonMeasurement(kg: 0.0, at: date1)

        XCTAssertEqual(ms.carbonKg, 0.0)

        ms = CarbonMeasurement(by: CarbonEquivalent(planeKm: 2000.0), at: date1)
        XCTAssertEqual(ms.carbonKg.round(to: 2), 371.75)

        XCTAssertTrue(ms.description.contains("371.747212 at 2022-04-06"))
    }
}
