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
    @Test("should create table only once")
    func name2() async throws {
        let tempFolderURL = FileManager.default.temporaryDirectory
        let tempOutFileURL = tempFolderURL.appending(component: "test1.sqlite")

        do { try FileManager.default.removeItem(at: tempOutFileURL) } catch {}

        print(tempOutFileURL.absoluteString)

        let db = try! SQLiteDB.fromPath(filepath: tempOutFileURL.absoluteString)

        try! db.createMeasurementTable()
        try! db.createMeasurementTable()
    }

    private let cm2 = CarbonMeasurement(kg: 42.0, at: date2, comment: "kurwa comment")
    @Test("should insert and retrieve single measurement") func testName() async throws {
        let tempFolderURL = FileManager.default.temporaryDirectory
        let tempOutFileURL = tempFolderURL.appending(component: "test2.sqlite")

        do { try FileManager.default.removeItem(at: tempOutFileURL) } catch {}

        print(tempOutFileURL.absoluteString)
        let db = try! SQLiteDB.fromPath(filepath: tempOutFileURL.absoluteString)

        try! db.createMeasurementTable()

        let service = SQLitePersistenceService(dbPath: tempOutFileURL)

        // when
        try await service.persist(measurement: cm2, id: "kurwa")
        let persisted = try #require(try service.load(measurementId: "kurwa"))

        #expect(persisted.carbonKg == 42)
        #expect(persisted.date.description == "2022-01-02 12:00:00 +0000")
        #expect(persisted.comment == "kurwa comment")
    }
}
