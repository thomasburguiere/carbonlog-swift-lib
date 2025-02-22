import Foundation
import Testing

@testable import CarbonLogLib

private struct EqToCarbonTestCase {
    let type: CarbonEquivalentType
    let amount: Double
    let expectedCo2Kg: Double
}

private let eqToCo2Cases = [
    EqToCarbonTestCase(type: .beefMeal, amount: 1, expectedCo2Kg: 7.14),
    EqToCarbonTestCase(type: .chickenKg, amount: 0.5, expectedCo2Kg: 9.1),
    EqToCarbonTestCase(type: .eggsKg, amount: 1, expectedCo2Kg: 5.3),
    EqToCarbonTestCase(type: .nuclearKWh, amount: 10, expectedCo2Kg: 1.4),
    EqToCarbonTestCase(type: .hydroKWh, amount: 10, expectedCo2Kg: 0.4),
    EqToCarbonTestCase(type: .carKm, amount: 10, expectedCo2Kg: 3.72),
]

private struct CarbonToEqTestCase {
    let co2Kg: Double
    let type: CarbonEquivalentType
    let expectedEqAmount: Double
}

private let co2ToEqCases = [
    CarbonToEqTestCase(co2Kg: 1.0, type: .beefMeal, expectedEqAmount: 0.14),
]

@Suite("Carbon Conversion tests")
struct CarbonConverterTests {
    @Test("should convert equivalent amounts to carbon Kgs", arguments: eqToCo2Cases)
    fileprivate func shouldConvertToKg(tc: EqToCarbonTestCase) async throws {
        let eq = CarbonEquivalent(type: tc.type, amount: tc.amount)
        #expect(eq.carbonKg.round(to: 2) == tc.expectedCo2Kg)
    }

    @Test("should convert co2 Kgs to equivalent amounts", arguments: co2ToEqCases)
    fileprivate func shouldConvertToEq(tc: CarbonToEqTestCase) async throws {
        let eq = CarbonEquivalent(carbonKg: tc.co2Kg)
        #expect(eq.asType(tc.type).round(to: 2) == tc.expectedEqAmount)
    }

    @Test("should generate CarboneEquivalent description")
    func generateEquivalentComment() async throws {
        var description = CarbonEquivalent(type: .carKm, amount: 250).description
        #expect(description == "250.00 carKm")

        description = CarbonEquivalent(carbonKg: 33.0).description
        #expect(description == "33.00 carbonKg")
    }
}
