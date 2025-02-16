import Foundation
import Testing

@testable import CarbonLogLib

private let calendar: Calendar = .init(identifier: .gregorian)

let gmt = TimeZone(identifier: "GMT")
private let date1 =
    calendar
        .date(from: DateComponents(timeZone: gmt, year: 2022, month: 4, day: 6, hour: 12))!
struct CarbonMeasurementTests {
    @Test
    func test_init() {
        var ms = CarbonMeasurement(kg: 0.0, at: date1)

        #expect(ms.carbonKg == 0.0)

        ms = CarbonMeasurement(by: CarbonEquivalent(type: .planeKm, amount: 2000.0), at: date1)
        #expect(ms.carbonKg.round(to: 2) == 292)

        #expect(
            ms.description.starts(with: "292.00 Kg at 2022-04-06"),
            "expected description to start with \"371.747212 at 2022-04-06\", actual \"\(ms.description)\""
        )

        let now = Date()
        ms = CarbonMeasurement(kg: 2.5)
        #expect(
            ms.description.starts(with: "2.5"),
            "expected description to start with \"2.5\", actual: \"\(ms.description)\""
        )
        #expect(ms.date >= now)

        ms = CarbonMeasurement(by: CarbonEquivalent(type: .planeKm, amount: 2000.0))
        #expect(ms.carbonKg.round(to: 2) == 292.0)

        ms = CarbonMeasurement(kg: 292.0)
        #expect(ms.equivalent.asType(.planeKm).round(to: 0) == 2000.00)
    }

    @Test("should init measurement with no comment")
    func initNoComment() {
        let ms = CarbonMeasurement(kg: 1.0)

        #expect(ms.comment == nil)
    }

    @Test("should init measurement with custom comment")
    func initCustomComment() {
        let ms = CarbonMeasurement(kg: 1.0, comment: "my comment")

        #expect(ms.comment == "my comment")
    }

    @Test("should init measurement with comment based on equivalent")
    func initEquivalentComment() {
        let eq = CarbonEquivalent(type: .eggsKg, amount: 0.3)
        let ms = CarbonMeasurement(by: eq)

        #expect(ms.comment == "0.30 eggsKg")
    }

    @Test("should init measurement with comment based on equivalent inited in carbonkg")
    func initEquivalentCommentCarbon() {
        let eq = CarbonEquivalent(carbonKg: 1.0)
        let ms = CarbonMeasurement(by: eq)

        #expect(ms.comment == "1.00 carbonKg")
    }

    @Suite(".description")
    struct name {
        @Test("basic functionality")
        func decriptionBasic() async throws {
            let description = CarbonMeasurement(kg: 42.0, at: date1).description

            #expect(description == "42.00 Kg at 2022-04-06T12:00:00Z")
        }

        @Test
        func descriptionWithComment() async throws {
            let description = CarbonMeasurement(by: CarbonEquivalent(type: .beefMeal, amount: 1.0), at: date1)
                .description

            #expect(description == "7.14 Kg at 2022-04-06T12:00:00Z commment: 1.00 beefMeal")
        }
    }
}
