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

@Suite("MeasurementRepo Tests")
struct MeasurementRepoTests {
    private let cm1 = CarbonMeasurement(
        kg: 666.0,
        at: date2,
        comment: "kurwa comment 1",
        id: "id-1"
    )
    private let cm2 = CarbonMeasurement(
        kg: 42.0,
        at: date2,
        comment: "kurwa comment 2",
        id: "id-2"
    )
    private let cm3 = CarbonMeasurement(
        kg: 43.0,
        at: date2,
        comment: "kurwa comment 3",
        id: "id-3"
    )
    private let log = CarbonLog(id: "logId")

    @Test
    func shouldReadAllLogMeasurements() async throws {
        let tempOutFileURL = ensureEmptyTempFile(filename: "test-readall-measurements.sqlite")
        let db = try SQLiteDB.fromPath(filepath: tempOutFileURL.absoluteString)
        let repo = try SQLiteMeasurementRepo(db: db)
        let logRepo = try SQLiteLogRepo(db: db)

        // given
        try logRepo.create(log: log)
        try repo.create(measurement: cm1, forLogId: "logId")
        try repo.create(measurement: cm2, forLogId: "logId")
        try repo.create(measurement: cm3, forLogId: "logId")

        // when
        let result = try repo.readMany(forLogId: "logId")
        // then
        #expect(result.count == 3)
    }
}
