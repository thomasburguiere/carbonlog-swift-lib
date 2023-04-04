import Foundation

fileprivate struct CarbonKgRatios {
    static let beefMeal = 0.14
    
    fileprivate struct Food {
        static let chickenMeal = 0.63
        static let chickenKg = 0.05494505495 // based on https://www.co2everything.com/co2e-of/chicken
        static let eggsKg = 0.1886792453 // based on https://www.co2everything.com/co2e-of/eggs
        static let veggieMeal = 1.96
        static let tapWaterLiters = 7575.76
        static let bottledWaterLiter = 2.21
    }
    static let heatingDayGas = 0.54
    
    fileprivate struct Travel {
        static let planeKm = 5.38
        static let trainKm = 578.8
        static let carKm = 5.18
    }
    
    fileprivate struct HighTech {
        static let smartPhone = 0.03
        static let laptop = 0.006
        static let computer24InchScreen = 0.004
        static let tv45Inch = 0.003
    }
    
    static let denimPants = 0.043
    static let pocketBook = 0.085
    static let sofa = 0.005
    static let cottonTShirt = 0.019
    static let a4PaperSheet = 218.34
    static let houseTrashKg = 2.59
}

public struct CarbonEquivalent{
    public var carbonKg: Double
    
    public init(carbonKg: Double) {
        self.carbonKg = carbonKg
    }
    
    
    public init(carKm: Double) { carbonKg = carKm / CarbonKgRatios.Travel.carKm }
    public init(planeKm: Double) {carbonKg = planeKm / CarbonKgRatios.Travel.planeKm}
    public init(trainKm: Double) {carbonKg = trainKm / CarbonKgRatios.Travel.trainKm}
    public init(beefMeal: Double) { carbonKg = beefMeal / CarbonKgRatios.beefMeal }
    public init(chickenMeal: Double) {carbonKg = chickenMeal / CarbonKgRatios.Food.chickenMeal}
    public init(chickenKg: Double) {carbonKg = chickenKg / CarbonKgRatios.Food.chickenKg}
    public init(eggsKg: Double) {carbonKg = eggsKg / CarbonKgRatios.Food.eggsKg}
    public init(veggieMeal: Double) {carbonKg = veggieMeal / CarbonKgRatios.Food.veggieMeal}
    public init(tapWaterLiters: Double) {carbonKg = tapWaterLiters / CarbonKgRatios.Food.tapWaterLiters}
    public init(bottledWaterLiter: Double) {carbonKg = bottledWaterLiter / CarbonKgRatios.Food.bottledWaterLiter}
    public init(heatingDayGas: Double) {carbonKg = heatingDayGas / CarbonKgRatios.heatingDayGas}
    public init(smartPhone: Double) {carbonKg = smartPhone / CarbonKgRatios.HighTech.smartPhone}
    public init(denimPants: Double) {carbonKg = denimPants / CarbonKgRatios.denimPants}
    public init(pocketBook: Double) {carbonKg = pocketBook / CarbonKgRatios.pocketBook}
    public init(sofa: Double) {carbonKg = sofa / CarbonKgRatios.sofa}
    public init(cottonTShirt: Double) {carbonKg = cottonTShirt / CarbonKgRatios.cottonTShirt}
    public init(laptop: Double) {carbonKg = laptop / CarbonKgRatios.HighTech.laptop}
    public init(computer24InchScreen: Double) {carbonKg = computer24InchScreen / CarbonKgRatios.HighTech.computer24InchScreen}
    public init(tv45Inch: Double) {carbonKg = tv45Inch / CarbonKgRatios.HighTech.tv45Inch}
    public init(a4PaperSheet: Double) {carbonKg = a4PaperSheet / CarbonKgRatios.a4PaperSheet}
    public init(houseTrashKg: Double) {carbonKg = houseTrashKg / CarbonKgRatios.houseTrashKg}
    
    public var carKm: Double {
        get {carbonKg * CarbonKgRatios.Travel.carKm}
        set(carKm) {carbonKg = carKm / CarbonKgRatios.Travel.carKm}
    }
    public var planeKm: Double {
        get {carbonKg * CarbonKgRatios.Travel.planeKm}
        set(planeKm) {carbonKg = planeKm / CarbonKgRatios.Travel.planeKm}
    }
    public var trainKm: Double {
        get {carbonKg * CarbonKgRatios.Travel.trainKm}
        set(trainKm) {carbonKg = trainKm / CarbonKgRatios.Travel.trainKm}
    }
    public var beefMeal: Double {
        get {carbonKg * CarbonKgRatios.beefMeal}
        set(beefMeal) {carbonKg = beefMeal / CarbonKgRatios.beefMeal}
    }
    public var chickenMeal: Double {
        get {carbonKg * CarbonKgRatios.Food.chickenMeal}
        set(chickenMeal) {carbonKg = chickenMeal / CarbonKgRatios.Food.chickenMeal}
    }
    public var chickenKg: Double {
        get {carbonKg * CarbonKgRatios.Food.chickenKg}
        set(chickenKg) {carbonKg = chickenKg / CarbonKgRatios.Food.chickenKg}
    }
    public var eggsKg: Double {
        get {carbonKg * CarbonKgRatios.Food.eggsKg}
        set(eggsKg) {carbonKg = eggsKg / CarbonKgRatios.Food.eggsKg}
    }
    public var veggieMeal: Double {
        get {carbonKg * CarbonKgRatios.Food.veggieMeal}
        set(veggieMeal) {carbonKg = veggieMeal / CarbonKgRatios.Food.veggieMeal}
    }
    public var smartPhone: Double {
        get {carbonKg * CarbonKgRatios.HighTech.smartPhone}
        set(smartPhone) {carbonKg = smartPhone / CarbonKgRatios.HighTech.smartPhone}
    }
    public var laptop: Double {
        get {carbonKg * CarbonKgRatios.HighTech.laptop}
        set(laptop) {carbonKg = laptop / CarbonKgRatios.HighTech.laptop}
    }
    public var computer24InchScreen: Double {
        get {carbonKg * CarbonKgRatios.HighTech.computer24InchScreen}
        set(computer24InchScreen) {carbonKg = computer24InchScreen / CarbonKgRatios.HighTech.computer24InchScreen}
    }
    public var tv45Inch: Double {
        get {carbonKg * CarbonKgRatios.HighTech.tv45Inch}
        set(tv45Inch) {carbonKg = tv45Inch / CarbonKgRatios.HighTech.tv45Inch}
    }
    public var denimPants: Double {
        get {carbonKg * CarbonKgRatios.denimPants}
        set(denimPants) {carbonKg = denimPants / CarbonKgRatios.denimPants}
    }
    public var pocketBook: Double {
        get {carbonKg * CarbonKgRatios.pocketBook}
        set(pocketBook) {carbonKg = pocketBook / CarbonKgRatios.pocketBook}
    }
    public var sofa: Double {
        get {carbonKg * CarbonKgRatios.sofa}
        set(sofa) {carbonKg = sofa / CarbonKgRatios.sofa}
    }
    public var cottonTShirt: Double {
        get {carbonKg * CarbonKgRatios.cottonTShirt}
        set(cottonTShirt) {carbonKg = cottonTShirt / CarbonKgRatios.cottonTShirt}
    }
    public var a4PaperSheet: Double {
        get {carbonKg * CarbonKgRatios.a4PaperSheet}
        set(a4PaperSheet) {carbonKg = a4PaperSheet / CarbonKgRatios.a4PaperSheet}
    }
    public var houseTrashKg: Double {
        get {carbonKg * CarbonKgRatios.houseTrashKg}
        set(houseTrashKg) {carbonKg = houseTrashKg / CarbonKgRatios.houseTrashKg}
    }
}

