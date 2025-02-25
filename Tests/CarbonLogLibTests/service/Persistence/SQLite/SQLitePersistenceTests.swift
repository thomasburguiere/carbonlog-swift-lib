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
struct SqlitePersistenceTests {
    @Suite("SQLiteDB")
    struct SQLiteDBTests {
        @Test("should create table only once and throw error when calling createTable() twice")
        func shouldThrowWhenCreatingTableTwice() async throws {
            let tempOutFileURL = ensureEmptyTempFile(filename: "test1.sqlite")

            let tableQuery = """
                CREATE TABLE dummy (
                    id TEXT,
                    PRIMARY KEY(id)
                )
            """
            let db = try! SQLiteDB.fromPath(filepath: tempOutFileURL.absoluteString)

            try! db.createTable("dummy", withCreateQuery: tableQuery)
            #expect(try! db.tableExists(tableName: "dummy") == true)
            #expect(throws: SQLError.DuplicateTable("dummy")) {
                try db.createTable("dummy", withCreateQuery: tableQuery)
            }
        }

        @Test(
            "should create table only once and not throw error when calling createTableIfNotExist() twice"
        )
        func shouldNotThrowWhenTryCreatingTableTwice() async throws {
            let tempOutFileURL = ensureEmptyTempFile(filename: "test1b.sqlite")

            let tableQuery = """
                CREATE TABLE dummy (
                    id TEXT,
                    PRIMARY KEY(id)
                )
            """
            let db = try! SQLiteDB.fromPath(filepath: tempOutFileURL.absoluteString)

            try! db.createTableIfNotExist("dummy", withCreateQuery: tableQuery)
            try! db.createTableIfNotExist("dummy", withCreateQuery: tableQuery)

            #expect(try! db.tableExists(tableName: "dummy") == true)
        }
    }

    @Suite("SqlPersistenceService")
    struct SqlitePersistenceServiceTests {
        @Suite("Measurement Tests")
        struct MeasurementTests {
            private let cm2 = CarbonMeasurement(
                kg: 42.0,
                at: date2,
                comment: "kurwa comment",
                id: "id-2"
            )

            @Test("should insert, load and delete single measurement")
            func shouldInsertLoadAndDeleteMeasurment() async throws {
                let tempOutFileURL = ensureEmptyTempFile(filename: "test2.sqlite")

                let service = try! SQLPersistenceService(
                    logRepo: SQLiteLogRepo(dbPath: tempOutFileURL),
                    measurementRepo: SQLiteMeasurementRepo(dbPath: tempOutFileURL)
                )

                let log = CarbonLog(id: "another-log")
                try! await service.persist(log: log)

                // when
                try service.persist(measurement: cm2, forLogId: log.id)
                // then
                let persisted = try #require(try service.load(measurementId: "id-2"))
                #expect(persisted.carbonKg == 42)
                #expect(persisted.date.description == "2022-01-02 12:00:00 +0000")
                #expect(persisted.comment == "kurwa comment")
                #expect(persisted.id == "id-2")

                // when
                try service.delete(measurement: cm2)
                // then
                let deleted = try service.load(measurementId: "id-2")
                #expect(deleted == nil)
            }

            @Test("should update single measurement")
            func shouldUpdateMeasurement() async throws {
                let tempOutFileURL =
                    ensureEmptyTempFile(filename: "test-updated-measurement.sqlite")

                let logRepo = try! SQLiteLogRepo(dbPath: tempOutFileURL)
                let service = try! SQLPersistenceService(
                    logRepo: logRepo,
                    measurementRepo: SQLiteMeasurementRepo(dbPath: tempOutFileURL)
                )

                let log = CarbonLog(id: "log-something")
                try logRepo.create(log: log)

                // given
                try service.persist(measurement: cm2, forLogId: log.id)
                let persisted: CarbonMeasurement = try #require(try service
                    .load(measurementId: "id-2"))
                #expect(persisted.carbonKg == 42)

                // when
                let updatedMeasurement = CarbonMeasurement(
                    kg: 666,
                    at: cm2.date.addingTimeInterval(86400), // + 1 day
                    comment: "updated comment",
                    id: cm2.id
                )
                print(tempOutFileURL)
                try service.persist(measurement: updatedMeasurement, forLogId: log.id)
                let persistedUpdated = try #require(try service.load(measurementId: "id-2"))

                // then
                #expect(persistedUpdated.carbonKg == 666)
                #expect(persistedUpdated.comment == "updated comment")
            }

            @Test("Should throw error when persisting measurement referring a non existing log")
            func shouldNotInsertMeasurementWithWrongLogReference() throws {
                let tempOutFileURL = ensureEmptyTempFile(filename: "test4.sqlite")

                let service = try! SQLPersistenceService(
                    logRepo: SQLiteLogRepo(dbPath: tempOutFileURL),
                    measurementRepo: SQLiteMeasurementRepo(dbPath: tempOutFileURL)
                )

                // given
                print(tempOutFileURL.absoluteString)
                #expect(throws: Error.self) {
                    try service.persist(measurement: cm2, forLogId: "NOOP")
                }
            }

            @Test("Should throw error when appending same measurement twice")
            func shouldThrowErrorWhenAppendingExisting() async throws {
                let tempOutFileURL = ensureEmptyTempFile(filename: "test5.sqlite")
                let logRepo = try! SQLiteLogRepo(dbPath: tempOutFileURL)
                let service = try! SQLPersistenceService(
                    logRepo: logRepo,
                    measurementRepo: SQLiteMeasurementRepo(dbPath: tempOutFileURL)
                )

                let log = CarbonLog(id: "id-55")
                try logRepo.create(log: log)
                try await service.append(measurement: cm2, toLogWithId: log.id)

                await #expect(throws: PersistenceError
                    .inconsistentOperation("Trying to append a measurement which already exists"))
                {
                    try await service.append(measurement: cm2, toLogWithId: log.id)
                }
            }
        }

        @Suite("Log Tests")
        struct LogTests {
            private let cm1 = CarbonMeasurement(
                by: CarbonEquivalent(type: .carKm, amount: 333),
                at: date1,
                id: "id-1"
            )
            private let cm2 = CarbonMeasurement(
                by: CarbonEquivalent(type: .carKm, amount: 333),
                at: date2,
                id: "id-2"
            )

            @Test("Should persist and load empty log")
            func shouldPersistLoadEmptyLog() async throws {
                let fileUrl = ensureEmptyTempFile(filename: "test-5.sqlite")

                let service = try! SQLPersistenceService(
                    logRepo: SQLiteLogRepo(dbPath: fileUrl),
                    measurementRepo: SQLiteMeasurementRepo(dbPath: fileUrl)
                )

                let log = CarbonLog(id: "my-log")
                // when
                try await service.persist(log: log)
                let persistedLog = try await service.load(id: log.id)

                // then
                #expect(persistedLog != nil)
            }

            @Test("Should persist and load log with multiple measurements")
            func shouldPersistLoadLogWithMultipleMeasurements() async throws {
                let fileUrl = ensureEmptyTempFile(filename: "test-6.sqlite")
                let service = try! SQLPersistenceService(
                    logRepo: SQLiteLogRepo(dbPath: fileUrl),
                    measurementRepo: SQLiteMeasurementRepo(dbPath: fileUrl)
                )
                let log = CarbonLog(with: [cm1, cm2], id: "my-log")

                // when
                try await service.persist(log: log)
                let persistedLog = try #require(await service.load(id: log.id))

                // then
                #expect(persistedLog.measurements.count == 2)
            }

            @Test("Should persist and load log with multiple measurements")
            func shouldUpdateLogWithMultipleMeasurements() async throws {
                let fileUrl =
                    ensureEmptyTempFile(filename: "test-update-multuple-measurements.sqlite")
                let service = try! SQLPersistenceService(
                    logRepo: SQLiteLogRepo(dbPath: fileUrl),
                    measurementRepo: SQLiteMeasurementRepo(dbPath: fileUrl)
                )
                let log = CarbonLog(with: [cm1, cm2], id: "my-log")
                try await service.persist(log: log)
                var persistedLog = try #require(await service.load(id: log.id))
                #expect(persistedLog.measurements.count == 2)

                // when
                let cm2Updated = CarbonMeasurement(
                    kg: 1983,
                    at: cm2.date,
                    comment: "cm2 updated",
                    id: cm2.id
                )
                let newCm = CarbonMeasurement(
                    kg: 10000,
                    at: cm2.date,
                    comment: "new cm",
                    id: "newCmId"
                )
                let logUpdated = CarbonLog(with: [cm2Updated, newCm], id: log.id)
                try await service.persist(log: logUpdated)

                // then
                persistedLog = try #require(await service.load(id: log.id))
                #expect(persistedLog.measurements.count == 2)

                let cm2UpdatedInDb = persistedLog.measurements
                    .first { $0.id == cm2.id }
                #expect(cm2UpdatedInDb!.comment == "cm2 updated")
                #expect(cm2UpdatedInDb!.carbonKg == 1983)
                #expect(cm2UpdatedInDb!.date == cm2.date)

                let newCmInDb = persistedLog.measurements
                    .first { $0.id == "newCmId" }
                #expect(newCmInDb!.comment == "new cm")
                #expect(newCmInDb!.carbonKg == 10000)
                #expect(newCmInDb!.date == cm2.date)
            }
        }
    }
}
