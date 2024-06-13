//
//  WeatherResult.swift
//  
//

import Foundation
import JsonModel
import ResultModel

extension SerializableResultType {
    public static let weather: SerializableResultType = "weather"
}

/// A `WeatherResult` includes results for both weather and air quality in a consolidated result.
/// Because this result must be mutable, it is defined as a class.
public final class WeatherResult : SerializableResultData {
    private enum CodingKeys : String, OrderedEnumCodingKey {
        case identifier, serializableType = "type", startDate, endDate, weather, airQuality
    }
    public private(set) var serializableType: SerializableResultType = .weather

    public let identifier: String
    public var startDate: Date = Date()
    public var endDate: Date = Date()
    public var weather: WeatherServiceResult?
    public var airQuality: AirQualityServiceResult?
    
    public init(identifier: String) {
        self.identifier = identifier
    }
    
    public func deepCopy() -> WeatherResult {
        let copy = WeatherResult(identifier: identifier)
        copy.startDate = startDate
        copy.endDate = endDate
        copy.weather = weather
        copy.airQuality = airQuality
        return copy
    }
}

extension WeatherResult : FileArchivable {
    public func buildArchivableFileData(at stepPath: String?) throws -> (fileInfo: FileInfo, data: Data)? {
        let fileInfo = FileInfo(filename: "\(identifier).json",
                                timestamp: startDate,
                                contentType: "application/json",
                                identifier: identifier,
                                stepPath: stepPath,
                                jsonSchema: self.jsonSchema,
                                metadata: nil)
        let data = try self.jsonEncodedData()
        return (fileInfo, data)
    }
}

extension WeatherResult : DocumentableRootObject {
    public convenience init() {
        self.init(identifier: "weather")
    }
    
    public var jsonSchema: URL {
        URL(string: "\(type(of: self)).json", relativeTo: kBaseJsonSchemaURL)!
    }
    
    public var documentDescription: String? {
        "A `WeatherResult` includes results for both weather and air quality in a consolidated result."
    }
}

extension WeatherResult : DocumentableStruct {

    public static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        guard let key = codingKey as? CodingKeys else { return false }
        switch key {
        case .identifier, .serializableType, .startDate:
            return true
        default:
            return false
        }
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .serializableType:
            return .init(constValue: SerializableResultType.weather)
        case .identifier:
            return .init(propertyType: .primitive(.string))
        case .startDate, .endDate:
            return .init(propertyType: .format(.dateTime))
        case .airQuality:
            return .init(propertyType: .reference(AirQualityServiceResult.documentableType()))
        case .weather:
            return .init(propertyType: .reference(WeatherServiceResult.documentableType()))
        }
    }
    
    public static func examples() -> [WeatherResult] {
        let example = WeatherResult(identifier: "weather")
        example.airQuality = AirQualityServiceResult.examples().first
        example.weather = WeatherServiceResult.examples().first
        return [example]
    }
}

public protocol WeatherServiceResponse {
    var serviceType: WeatherServiceType { get }
    var identifier: String { get }
    var startDate: Date { get }
}

public struct WeatherServiceResult : Codable, Equatable, WeatherServiceResponse {
    private enum CodingKeys : String, OrderedEnumCodingKey {
        case identifier, providerName = "provider", startDate,
             temperature, seaLevelPressure, groundLevelPressure, humidity, clouds, rain, snow, wind
    }
    public var serviceType: WeatherServiceType { .weather }

    public let identifier: String
    public let providerName: WeatherServiceProviderName
    public var startDate: Date
    
    /// Current average temperature. Unit: Celsius
    public let temperature: Double?
    
    /// Atmospheric pressure at sea level. Unit: hPa
    public let seaLevelPressure: Double?
    
    /// Atmospheric pressure at ground level. Unit: hPa
    public let groundLevelPressure: Double?
    
    /// % Humidity.
    public let humidity: Double?
    
    /// % Cloudiness.
    public let clouds: Double?
    
    /// Recent rainfall.
    public let rain: Precipitation?
    
    /// Recent snowfall.
    public let snow: Precipitation?
    
    /// Current wind conditions.
    public let wind: Wind?
    
    public init(identifier: String,
                providerName: WeatherServiceProviderName,
                startDate: Date,
                temperature: Double?,
                seaLevelPressure: Double?,
                groundLevelPressure: Double?,
                humidity: Double?,
                clouds: Double?,
                rain: Precipitation?,
                snow: Precipitation?,
                wind: Wind?) {
        self.identifier = identifier
        self.providerName = providerName
        self.startDate = startDate
        self.temperature = temperature
        self.seaLevelPressure = seaLevelPressure
        self.groundLevelPressure = groundLevelPressure
        self.humidity = humidity
        self.clouds = clouds
        self.rain = rain
        self.snow = snow
        self.wind = wind
    }
    
    public struct Precipitation: Codable, Equatable {
        private enum CodingKeys : String, CodingKey, CaseIterable {
            case pastHour, pastThreeHours
        }
        /// Amount of precipitation in the past hour.
        public let pastHour: Double?
        /// Amount of precipitation in the past three hours.
        public let pastThreeHours: Double?
        
        public init(pastHour: Double?, pastThreeHours: Double?) {
            self.pastHour = pastHour
            self.pastThreeHours = pastThreeHours
        }
    }

    public struct Wind : Codable, Equatable {
        private enum CodingKeys : String, CodingKey, CaseIterable {
            case speed, degrees, gust
        }
        /// Wind speed. Unit: meter/sec
        public let speed: Double
        /// Wind direction, degrees (meteorological)
        public let degrees: Double?
        /// Wind gust. Unit: meter/sec
        public let gust: Double?
        
        public init(speed: Double, degrees: Double?, gust: Double?) {
            self.speed = speed
            self.degrees = degrees
            self.gust = gust
        }
    }
}

extension WeatherServiceResult : DocumentableStruct {
    public static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        guard let key = codingKey as? CodingKeys else { return false }
        switch key {
        case .identifier,.providerName,.startDate:
            return true
        default:
            return false
        }
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .identifier:
            return .init(propertyType: .primitive(.string), propertyDescription: "Result identifier")
        case .providerName:
            return .init(propertyType: .reference(WeatherServiceProviderName.documentableType()))
        case .startDate:
            return .init(propertyType: .format(.dateTime))
        case .clouds, .temperature, .groundLevelPressure, .seaLevelPressure, .humidity:
            return .init(propertyType: .primitive(.number))
        case .rain, .snow:
            return .init(propertyType: .reference(Precipitation.documentableType()))
        case .wind:
            return .init(propertyType: .reference(Wind.documentableType()))
        }
    }
    
    public static func examples() -> [WeatherServiceResult] {
        [WeatherServiceResult(identifier: "weather", providerName: .openWeather, startDate: Date(), temperature: 20, seaLevelPressure: nil, groundLevelPressure: nil, humidity: 0.9, clouds: 0.4, rain: nil, snow: nil, wind: nil)]
    }
}

extension WeatherServiceResult.Precipitation : DocumentableStruct {

    public static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        false
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .pastHour:
            return .init(propertyType: .primitive(.number), propertyDescription: "Precipitation in the past hour.")
        case .pastThreeHours:
            return .init(propertyType: .primitive(.number), propertyDescription: "Precipitation in the past 3 hours.")
        }
    }
    
    public static func examples() -> [WeatherServiceResult.Precipitation] {
        [.init(pastHour: 5.0, pastThreeHours: 12.0)]
    }
}

extension WeatherServiceResult.Wind : DocumentableStruct {
    public static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        (codingKey as? CodingKeys) == .speed
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .speed, .degrees, .gust:
            return .init(propertyType: .primitive(.number))
        }
    }
    
    public static func examples() -> [WeatherServiceResult.Wind] {
        [.init(speed: 5, degrees: 20, gust: 1)]
    }
}

public struct AirQualityServiceResult : Codable, Equatable, WeatherServiceResponse {
    private enum CodingKeys : String, OrderedEnumCodingKey {
        case identifier, providerName = "provider", startDate, aqi, category
    }
    public var serviceType: WeatherServiceType { .airQuality }
    
    public let identifier: String
    public let providerName: WeatherServiceProviderName
    public var startDate: Date
    public let aqi: Int?
    public let category: Category?
    
    public init(identifier: String,
                providerName: WeatherServiceProviderName,
                startDate: Date,
                aqi: Int?,
                category: Category?) {
        self.identifier = identifier
        self.providerName = providerName
        self.startDate = startDate
        self.aqi = aqi
        self.category = category
    }

    public struct Category : Codable, Equatable {
        private enum CodingKeys : String, CodingKey, CaseIterable {
            case number, name
        }
        public let number: Int
        public let name: String
        public init(number: Int, name: String) {
            self.number = number
            self.name = name
        }
    }
}

extension AirQualityServiceResult.Category : DocumentableStruct {

    public static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        true
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .name:
            return .init(propertyType: .primitive(.string))
        case .number:
            return .init(propertyType: .primitive(.number))
        }
    }
    
    public static func examples() -> [AirQualityServiceResult.Category] {
        [AirQualityServiceResult.Category(number: 1, name: "Good")]
    }
}

extension AirQualityServiceResult : DocumentableStruct {

    public static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        guard let key = codingKey as? CodingKeys else { return false }
        switch key {
        case .identifier,.providerName,.startDate:
            return true
        default:
            return false
        }
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .identifier:
            return .init(propertyType: .primitive(.string))
        case .startDate:
            return .init(propertyType: .format(.dateTime))
        case .providerName:
            return .init(propertyType: .reference(WeatherServiceProviderName.documentableType()))
        case .aqi:
            return .init(propertyType: .primitive(.number), propertyDescription: "Air Quality Index")
        case .category:
            return .init(propertyType: .reference(Category.documentableType()))
        }
    }
    
    public static func examples() -> [AirQualityServiceResult] {
        [AirQualityServiceResult(identifier: "airQuality", providerName: "airNow", startDate: Date(), aqi: 2, category: .init(number: 2, name: "Moderate"))]
    }
}
