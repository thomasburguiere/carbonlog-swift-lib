//
//  File.swift
//  
//
//  Created by Thomas Burguiere on 28.05.22.
//

import Foundation

struct CarbonKgRatios {
    
    static let beefMeal = 0.14
    static let chickenMeal = 0.63
    static let veggieMeal = 1.96
    static let heatingDayGas = 0.54
    static let carKm = 5.18
    static let planeKm = 5.38
    static let trainKm = 578.8
    static let smartPhone = 0.03
    static let denimPants = 0.043
    static let pocketBook = 0.085
    static let sofa = 0.005
    static let cottonTShirt = 0.019
    static let laptop = 0.006
    static let computer24InchScreen = 0.004
    static let tv45Inch = 0.003
    static let a4PaperSheet = 218.34
    static let houseTrashKg = 2.59
    static let tapWaterLiters = 7575.76
    static let bottledWaterLiter = 2.21
    
}

public struct CarbonEquivalent{
    public let carbonKg: Double
    
    public init(carbonKg: Double) {
        self.carbonKg = carbonKg
    }
    
    public init(beefMeal: Double) {
        carbonKg = beefMeal / CarbonKgRatios.beefMeal
    }
    
    public init(carKm: Double) {
        carbonKg = carKm / CarbonKgRatios.carKm
    }
    
    public var beefMeal: Double {
        return carbonKg * CarbonKgRatios.beefMeal
    }
}

