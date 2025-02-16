import Foundation
import Testing

@testable import CarbonLogLib

private let calendar: Calendar = .init(identifier: .gregorian)

private let date1 =
    calendar
        .date(from: DateComponents(year: 2022, month: 1, day: 1))!
private let date2 =
    calendar
        .date(from: DateComponents(year: 2022, month: 1, day: 2))!
private let date3 =
    calendar
        .date(from: DateComponents(year: 2022, month: 1, day: 3))!
private let date4 =
    calendar
        .date(from: DateComponents(year: 2022, month: 1, day: 4))!
private let date_2021 =
    calendar
        .date(from: DateComponents(year: 2021, month: 1, day: 4))!

struct CarbonLogTests {
    @Test
    func should_init_with_default_id_and_empty_measurements() async throws {
        // when
        let log = CarbonLog()

        // then
        #expect(log.id.count >= 0, "expected log id '\(log.id)', to be non empty string")
        #expect(log.measurements.count == 0, "expected log measurments to be empty array")
    }

    @Test("should get results when in range")
    func should_get_results_when_in_range() {
        // given
        let cm2 = CarbonMeasurement(kg: 2.0, at: date2)
        let cm3 = CarbonMeasurement(kg: 3.0, at: date3)
        let log = CarbonLog(with: [cm2, cm3])

        // when
        let result = log.getRangeCarbonKgs(from: date1, to: date4)

        // then
        #expect(result == 5.0)
    }

    @Test("should get results when in range with added data")
    func should_get_results_when_in_range_with_added_data() {
        // given
        let cm2 = CarbonMeasurement(kg: 2.0, at: date2)
        let cm3 = CarbonMeasurement(kg: 3.0, at: date3)
        let log = CarbonLog(with: [cm2, cm3])

        let addedCm = CarbonMeasurement(kg: 11.0, at: date2)

        let updatedLog = log.add(measurements: [addedCm])

        // when
        let result = updatedLog.getRangeCarbonKgs(from: date1, to: date4)

        // then
        #expect(result == 16.0)
    }

    @Test("should get nothing when outside range")
    func should_get_nothing_when_outside_range() {
        // given
        let cm2 = CarbonMeasurement(kg: 2.0, at: date2)
        let cm3 = CarbonMeasurement(kg: 3.0, at: date3)
        let log = CarbonLog(with: [cm2, cm3])

        // when
        let result = log.getRangeCarbonKgs(from: date4, to: date4)

        // then
        #expect(result == 0.0)
    }

    @Test("should get nothing when search range exclusive")
    func should_get_nothing_when_search_range_exclusive() {
        // given
        let cm2 = CarbonMeasurement(kg: 2.0, at: date2)
        let cm3 = CarbonMeasurement(kg: 3.0, at: date3)
        let log = CarbonLog(with: [cm2, cm3])

        // when
        let result = log.getRangeCarbonKgs(from: date3, to: date4)

        // then
        #expect(result == 0.0)
    }

    @Test("should get result when search range inclusive")
    func should_get_result_when_search_range_inclusive() {
        // given
        let cm2 = CarbonMeasurement(kg: 2.0, at: date2)
        let cm3 = CarbonMeasurement(kg: 3.0, at: date3)
        let log = CarbonLog(with: [cm2, cm3])

        // when
        let result = log.getRangeCarbonKgs(from: date3, to: date4, inclusive: true)

        // then
        #expect(result == 3.0)
    }

    @Test
    func should_get_result_for_current_year() {
        // given
        let todayDate = Date()
        let cm2 = CarbonMeasurement(kg: 2.0, at: todayDate)
        let cm3 = CarbonMeasurement(kg: 3.0, at: date_2021)
        let log = CarbonLog(with: [cm2, cm3])

        // when
        let result = log.getCurrentYearCarbonKgs()

        // then
        #expect(result == cm2.carbonKg)
    }
}
