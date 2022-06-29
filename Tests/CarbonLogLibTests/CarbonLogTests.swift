@testable import CarbonLogLib
import XCTest

import Foundation

let calendar: Calendar = Calendar(identifier: .gregorian)

let date1 = calendar
    .date(from: DateComponents(year:2022, month: 1, day: 1))!
let date2 = calendar
    .date(from: DateComponents(year:2022, month: 1, day: 2))!
let date3 = calendar
    .date(from: DateComponents(year:2022, month: 1, day: 3))!
let date4 = calendar
    .date(from: DateComponents(year:2022, month: 1, day: 4))!
let date_2021 = calendar
    .date(from: DateComponents(year:2021, month: 1, day: 4))!

public class CarbonLogTests: XCTestCase {
    func test_get_results_when_in_range() {
        // given
        let cm2 = CarbonMeasurement(kg: 2.0, at: date2)
        let cm3 = CarbonMeasurement(kg: 3.0, at: date3)
        let log = CarbonLog(with: [cm2, cm3])
        
        // when
        let result = log.getRangeCarbonKgs(from: date1, to: date4)
        
        // then
        XCTAssertEqual(result, 5.0)
    }
    
    func test_get_results_when_in_range_with_added_data() {
        // given
        let cm2 = CarbonMeasurement(kg: 2.0, at: date2)
        let cm3 = CarbonMeasurement(kg: 3.0, at: date3)
        let log = CarbonLog(with: [cm2, cm3])
        
        let addedCm = CarbonMeasurement(kg: 11.0, at: date2)
        
        let updatedLog = log.add(measurements: [addedCm])
        
        // when
        let result = updatedLog.getRangeCarbonKgs(from: date1, to: date4)
        
        // then
        XCTAssertEqual(result, 16.0)
    }
    
    func test_get_nothing_when_outside_range() {
        // given
        let cm2 = CarbonMeasurement(kg: 2.0, at: date2)
        let cm3 = CarbonMeasurement(kg: 3.0, at: date3)
        let log = CarbonLog(with: [cm2, cm3])
        
        // when
        let result = log.getRangeCarbonKgs(from: date4, to: date4)
        
        // then
        XCTAssertEqual(result, 0.0)
    }
    
    func test_get_nothing_when_search_range_exclusive() {
        // given
        let cm2 = CarbonMeasurement(kg: 2.0, at: date2)
        let cm3 = CarbonMeasurement(kg: 3.0, at: date3)
        let log = CarbonLog(with: [cm2, cm3])
        
        // when
        let result = log.getRangeCarbonKgs(from: date3, to: date4)
        
        // then
        XCTAssertEqual(result, 0.0)
    }
    
    func test_get_result_when_search_range_inclusive() {
        // given
        let cm2 = CarbonMeasurement(kg: 2.0, at: date2)
        let cm3 = CarbonMeasurement(kg: 3.0, at: date3)
        let log = CarbonLog(with: [cm2, cm3])
        
        // when
        let result = log.getRangeCarbonKgs(from: date3, to: date4, inclusive: true)
        
        // then
        XCTAssertEqual(result, 3.0)
    }
    
    func test_get_result_for_current_year() {
        // given
        let todayDate = Date()
        let cm2 = CarbonMeasurement(kg: 2.0, at: todayDate)
        let cm3 = CarbonMeasurement(kg: 3.0, at: date_2021)
        let log = CarbonLog(with: [cm2, cm3])
        
        // when
        let result = log.getCurrentYearCarbonKgs()
        
        // then
        XCTAssertEqual(result, cm2.carbonKg)
    }
}