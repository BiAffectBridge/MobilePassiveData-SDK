//
//  DistanceRecord.swift
//  
//


import CoreLocation
import JsonModel

public let distanceRecordSchema = DocumentableRootArray(rootDocumentType: DistanceRecord.self,
                                              jsonSchema: .init(string: "\(DistanceRecord.self).json", relativeTo: kBaseJsonSchemaURL)!,
                                              documentDescription: "A list of distance measurements that are defined relative to one another rather than using GPS coordinates.")

/// A `DistanceRecord` is a `Codable` implementation of `SampleRecord` that can be used
/// to record CoreLocation samples for use in determining distance travelled.
///
/// - example:
///
/// ```
///     // Example json for a codable record.
///     let json = """
///                {
///                 "uptime" : 99652.677386361029,
///                 "relativeDistance" : 2.1164507282484935,
///                 "verticalAccuracy" : 3,
///                 "horizontalAccuracy" : 6,
///                 "stepPath" : "Cardio 12MT/run/runDistance",
///                 "course" : 76.873546882061802,
///                 "totalDistance" : 63.484948023273581,
///                 "speed" : 1.0289180278778076,
///                 "timestampDate" : "2018-01-04T23:49:34.135-08:00",
///                 "timestamp" : 210.47070598602295,
///                 "altitude" : 23.375564581136974
///                }
///                """.data(using: .utf8)! // our data in native (JSON) format
/// ```
public struct DistanceRecord: SampleRecord, DelimiterSeparatedEncodable {
    
    /// The absolute clock time.
    public let uptime: ClockUptime?
    
    /// Relative time to when the recorder was started.
    public let timestamp: SecondDuration?
    
    /// An identifier marking the current step.
    public let stepPath: String
    
    /// The date timestamp when the measurement was taken.
    public let timestampDate: Date?
    
    /// The Unix timestamp (seconds since 1970-01-01T00:00:00.000Z) when the measurement was taken.
    public let timestampUnix: TimeInterval?
    
    /// Returns the horizontal accuracy of the location in meters; null if the lateral location is invalid.
    public let horizontalAccuracy: Double?
    
    /// Returns the lateral distance between the current location and the previous location in meters.
    public let relativeDistance: Double?
    
    /// Returns the latitude coordinate of the current location; null if *only* relative distance
    /// should be recorded.
    public let latitude: Double?
    
    /// Returns the longitude coordinate of the current location; null if *only* relative distance
    /// should be recorded.
    public let longitude: Double?
    
    /// Returns the vertical accuracy of the location in meters; null if the altitude is invalid.
    public let verticalAccuracy: Double?
    
    /// Returns the altitude of the location in meters. Can be positive (above sea level) or negative (below sea level).
    public let altitude: Double?
    
    /// Sum of the relative distance measurements if the participant is supposed to be moving.
    /// Otherwise, this value will be null.
    public let totalDistance: Double?
    
    /// Returns the course of the location in degrees true North; null if course is invalid.
    /// - Range: 0.0 - 359.9 degrees, 0 being true North.
    public let course: Double?
    
    /// Returns the bearing to the location from the previous location in radians (clockwise from) true North.
    /// - Range: [0.0..2π), 0 being true North.
    public let bearingRadians: Double?
    
    /// Returns the speed of the location in meters/second; null if speed is invalid.
    public let speed: Double?
    
    /// Returns the floor of the building where the location was recorded; null if floor is not available.
    public let floor: Int?
    
    private enum CodingKeys : String, OrderedEnumCodingKey {
        case uptime, timestamp, stepPath, timestampDate, timestampUnix, horizontalAccuracy, relativeDistance, latitude, longitude, verticalAccuracy, altitude, totalDistance, course, bearingRadians, speed, floor
    }
    
    fileprivate init(uptime: ClockUptime?, timestamp: SecondDuration?, stepPath: String, timestampDate: Date?, timestampUnix: TimeInterval?, horizontalAccuracy: Double?, relativeDistance: Double?, latitude: Double?, longitude: Double?, verticalAccuracy: Double?, altitude: Double?, totalDistance: Double?, course: Double?, bearingRadians: Double?, speed: Double?, floor: Int?) {
        self.uptime = uptime
        self.timestamp = timestamp
        self.stepPath = stepPath
        self.timestampDate = timestampDate
        self.timestampUnix = timestampUnix
        self.horizontalAccuracy = horizontalAccuracy
        self.relativeDistance = relativeDistance
        self.latitude = latitude
        self.longitude = longitude
        self.verticalAccuracy = verticalAccuracy
        self.altitude = altitude
        self.totalDistance = totalDistance
        self.course = course
        self.bearingRadians = bearingRadians
        self.speed = speed
        self.floor = floor
    }
    
    /// Default initializer.
    /// - parameters:
    ///     - uptime: The clock uptime.
    ///     - timestamp: Relative time to when the recorder was started.
    ///     - stepPath: An identifier marking the current step.
    ///     - location: The `CLLocation` to record.
    ///     - previousLocation: The previous `CLLocation` or null if this is the first sample.
    ///     - totalDistance: Sum of the relative distance measurements.
    ///     - relativeDistanceOnly: Whether or not **only** relative distance should be recorded. Default = `true`
    public init(uptime: ClockUptime?, timestamp: SecondDuration?, stepPath: String, location: CLLocation, previousLocation: CLLocation?, totalDistance: Double?, relativeDistanceOnly: Bool = true) {
        self.uptime = uptime
        self.timestamp = timestamp
        self.stepPath = stepPath
        self.totalDistance = totalDistance
        self.timestampDate = location.timestamp
        self.timestampUnix = location.timestamp.timeIntervalSince1970
        self.speed = location.speed >= 0 ? location.speed : nil
        self.course = location.course >= 0 ? location.course : nil
        self.floor = location.floor?.level
        
        // Record the horizontal accuracy and relative distance
        if location.horizontalAccuracy >= 0 {
            self.horizontalAccuracy = location.horizontalAccuracy
            if let previous = previousLocation, previous.horizontalAccuracy >= 0 {
                self.bearingRadians = previous.rsd_bearingInRadians(to: location)
                self.relativeDistance = location.distance(from: previous)
            } else {
                self.bearingRadians = nil
                self.relativeDistance = nil
            }
            if relativeDistanceOnly {
                self.latitude = nil
                self.longitude = nil
            } else {
                self.latitude = location.coordinate.latitude
                self.longitude = location.coordinate.longitude
            }
        } else {
            self.horizontalAccuracy = nil
            self.bearingRadians = nil
            self.relativeDistance = nil
            self.latitude = nil
            self.longitude = nil
        }
        
        // Record the vertical accuracy
        if location.verticalAccuracy >= 0 {
            self.verticalAccuracy = location.verticalAccuracy
            self.altitude = location.altitude
        } else {
            self.verticalAccuracy = nil
            self.altitude = nil
        }
    }
}

extension CLLocation {
    static func rsd_toRadians(from degrees: CLLocationDegrees) -> Double {
        return (degrees / 180.0) * .pi
    }
    
    static func rsd_toDegrees(from radians: Double) -> CLLocationDegrees {
        return (radians / .pi) * 180.0
    }
    
    func rsd_bearingInRadians(to endLocation: CLLocation) -> Double {
        // https://www.igismap.com/formula-to-find-bearing-or-heading-angle-between-two-points-latitude-longitude/
        let theta_a = CLLocation.rsd_toRadians(from: self.coordinate.latitude)
        let La = CLLocation.rsd_toRadians(from: self.coordinate.longitude)
        let theta_b = CLLocation.rsd_toRadians(from: endLocation.coordinate.latitude)
        let Lb = CLLocation.rsd_toRadians(from: endLocation.coordinate.longitude)
        let delta_L = Lb - La
        let X = cos(theta_b) * sin(delta_L)
        let Y = cos(theta_a) * sin(theta_b) - sin(theta_a) * cos(theta_b) * cos(delta_L)
        
        return atan2(X, Y)
    }
}

extension DistanceRecord : DocumentableStruct {
    public static func codingKeys() -> [CodingKey] {
        return CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        codingKey.stringValue == CodingKeys.stepPath.stringValue
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .uptime:
            return .init(propertyType: .primitive(.number), propertyDescription: "System clock time.")
        case .timestamp:
            return .init(propertyType: .primitive(.number), propertyDescription: "Time that the system has been awake since last reboot.")
        case .stepPath:
            return .init(propertyType: .primitive(.string), propertyDescription: "An identifier marking the current step.")
        case .timestampDate:
            return .init(propertyType: .format(.dateTime), propertyDescription: "The date timestamp when the measurement was taken (if available).")
        case .timestampUnix:
            return .init(propertyType: .primitive(.number), propertyDescription: "The Unix timestamp (seconds since 1970-01-01T00:00:00.000Z) when the measurement was taken.")
        case .horizontalAccuracy:
            return .init(propertyType: .primitive(.number), propertyDescription: "The horizontal accuracy of the location in meters; null if the lateral location is invalid.")
        case .relativeDistance:
            return .init(propertyType: .primitive(.number), propertyDescription: "The lateral distance between the current location and the previous location in meters.")
        case .latitude:
            return .init(propertyType: .primitive(.number), propertyDescription: "The latitude coordinate of the current location; null if *only* relative distance should be recorded.")
        case .longitude:
            return .init(propertyType: .primitive(.number), propertyDescription: "The longitude coordinate of the current location; null if *only* relative distance should be recorded.")
        case .verticalAccuracy:
            return .init(propertyType: .primitive(.number), propertyDescription: "The vertical accuracy of the location in meters; null if the vertical location is invalid.")
        case .altitude:
            return .init(propertyType: .primitive(.number), propertyDescription: "The altitude of the location in meters. Can be positive (above sea level) or negative (below sea level).")
        case .totalDistance:
            return .init(propertyType: .primitive(.number), propertyDescription: "Sum of the relative distance measurements if the participant is supposed to be moving; null if participant is supposed to be standing still.")
        case .course:
            return .init(propertyType: .primitive(.number), propertyDescription: "The course of the location in degrees true North; null if course is invalid. Range: 0.0 - 359.9 degrees, 0 being true North.")
        case .bearingRadians:
            return .init(propertyType: .primitive(.number), propertyDescription: "The bearing to the location from the previous location in radians (clockwise from) true North. Range: [0.0..2π), 0 being true North.")
        case .speed:
            return .init(propertyType: .primitive(.number), propertyDescription: "The speed of the location in meters/second; null if speed is invalid.")
        case .floor:
            return .init(propertyType: .primitive(.integer), propertyDescription: "The floor of the building where the location was recorded; null if floor is not available.")
        }
    }
    
    public static func examples() -> [DistanceRecord] {
        let now = Date()
        let example = DistanceRecord(uptime: 99494.629004376795, timestamp: 52.422324001789093, stepPath: "Cardio 12MT/run/runDistance", timestampDate: now, timestampUnix: now.timeIntervalSince1970, horizontalAccuracy: 6, relativeDistance: 2.1164507282484935, latitude: nil, longitude: nil, verticalAccuracy: 3, altitude: 23.375564581136974, totalDistance: 63.484948023273581, course: 76.873546882061802, bearingRadians: 1.3416965, speed: 1.0289180278778076, floor: 3)
        
        return [example]
    }
}
