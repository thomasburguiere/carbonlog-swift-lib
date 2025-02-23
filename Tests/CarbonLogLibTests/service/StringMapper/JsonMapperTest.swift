import Foundation
import Testing

@testable import CarbonLogLib

private let calendar: Calendar = .init(identifier: .gregorian)

private let date1 =
    calendar
        .date(from: DateComponents(timeZone: gmt, year: 2022, month: 1, day: 1, hour: 12))!
private let date2 =
    calendar
        .date(from: DateComponents(timeZone: gmt, year: 2022, month: 1, day: 2, hour: 12))!
private let date3 =
    calendar
        .date(from: DateComponents(timeZone: gmt, year: 2022, month: 1, day: 3, hour: 12))!

@Suite("JSON extensions")
struct JsonExtensionsTest {
    private let cm2 = CarbonMeasurement(kg: 2.0, at: date2, id: "id-2")
    private let cm3 = CarbonMeasurement(kg: 3.0, at: date3, comment: "my comment", id: "id-3")

    let mapper = JsonMapper()

    @Test("should dump log with single measurement to JSON")
    func dumpLogSingleMeasurementsJson() async throws {
        let log = CarbonLog(with: [cm2], id: "jsonLog")
        let jsonString = mapper.logToString(log: log)

        #expect(jsonString?.contains(#""date":"2022-01-02T12:00:00Z""#) == true)
        #expect(jsonString?.contains(#""id":"id-2""#) == true)
        #expect(jsonString?.contains(#""carbonKg":2"#) == true)
    }

    @Test("should dump log with single measurement with comment to JSON")
    func dumpLogSingleMeasurementsAndCommentsJson() async throws {
        let log = CarbonLog(with: [cm3], id: "jsonLog")
        let jsonString = mapper.logToString(log: log)

        #expect(jsonString?.contains(#""date":"2022-01-03T12:00:00Z""#) == true)
        #expect(jsonString?.contains(#""carbonKg":3"#) == true)
        #expect(jsonString?.contains(#""id":"id-3""#) == true)
        #expect(jsonString?.contains(#""comment":"my comment"#) == true)
    }

    @Test("should dump log with multiple measurements to JSON")
    func dumpLogMultiMeasurementsJson() async throws {
        let log = CarbonLog(with: [cm2, cm3], id: "jsonLog")
        let jsonString = mapper.logToString(log: log)

        #expect(jsonString?.contains(#""date":"2022-01-02T12:00:00Z""#) == true)
        #expect(jsonString?.contains(#""carbonKg":2"#) == true)

        #expect(jsonString?.contains(#""date":"2022-01-03T12:00:00Z""#) == true)
        #expect(jsonString?.contains(#""carbonKg":3"#) == true)
        #expect(jsonString?.contains(#""comment":"my comment"#) == true)
    }

    @Test("should parse log from JSON")
    func parseLogJson() async throws {
        let jsonString = """
        {
          "measurements":[
            {"date":"2022-01-02T12:00:00Z","carbonKg":2,"id":"id-2"},
            {"date":"2022-01-03T12:00:00Z","carbonKg":3,"id":"id-3","comment":"my comment"}
          ],
          "id":"my-id"
        }
        """

        let log = try #require(mapper.stringToLog(string: jsonString))
        #expect(log.id == "my-id")
        let parsedCm2 = log.measurements.first { $0.id == "id-2" }
        let parsedCm3 = log.measurements.first { $0.id == "id-3" }
        #expect(parsedCm2?.carbonKg == 2)
        #expect(parsedCm3?.carbonKg == 3)
        #expect(parsedCm2?.date.ISO8601Format() == "2022-01-02T12:00:00Z")
        #expect(parsedCm3?.date.ISO8601Format() == "2022-01-03T12:00:00Z")
        #expect(parsedCm3?.comment == "my comment")
    }
}
