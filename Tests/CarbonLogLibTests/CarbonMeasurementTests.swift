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

        XCTAssertTrue(
            ms.description.starts(with: "371.747212 at 2022-04-06"),
            "expected description to start with \"371.747212 at 2022-04-06\", actual \"\(ms.description)\""
        )

        let now = Date()
        ms = CarbonMeasurement(carbonKg: 2.5)
        XCTAssertTrue(
            ms.description.starts(with: "2.5"),
            "expected description to start with \"2.5\", actual: \"\(ms.description)\""
        )
        XCTAssertTrue(ms.date >= now)

        ms = CarbonMeasurement(by: CarbonEquivalent(planeKm: 2000.0))
        XCTAssertEqual(ms.carbonKg.round(to: 2), 371.75)

        ms = CarbonMeasurement(carbonKg: 371.75)
        XCTAssertEqual(ms.equivalent.planeKm.round(to: 0), 2000.00)
    }
}
