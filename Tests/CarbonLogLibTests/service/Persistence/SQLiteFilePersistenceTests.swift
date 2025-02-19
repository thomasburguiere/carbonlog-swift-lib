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

@Suite("SQLite Persistence")
struct name {
    private let cm2 = CarbonMeasurement(kg: 42.0, at: date2)
    @Test func testName() async throws {
        let tempFolderURL = FileManager.default.temporaryDirectory
        let tempOutFileURL = tempFolderURL.appending(component: "test.sqlite")

        try FileManager.default.removeItem(at: tempOutFileURL)

        print(tempOutFileURL.absoluteString)
        let db = try? #require(openDatabase(filepath: tempOutFileURL.absoluteString))

        let createTableString = """
          CREATE TABLE "CarbonMeasurement" (
            "id"	TEXT NOT NULL UNIQUE,
            "carbonKg"	NUMERIC NOT NULL,
            "date"	TEXT NOT NULL,
            "comment"	TEXT,
            PRIMARY KEY("id")
          );
        """

        createTable(db: db, createTableString: createTableString)

        let service = SQLitePersistenceService(dbPath: tempOutFileURL)

        // when
        try await service.persist(measurement: cm2)
    }
}
