//
//  MotionRecord.swift
//  
//

import Foundation
import JsonModel

public let motionRecordSchema = DocumentableRootArray(rootDocumentType: MotionRecord.self,
                                          jsonSchema: .init(string: "\(MotionRecord.self).json", relativeTo: kBaseJsonSchemaURL)!,
                                          documentDescription: "A list of motion sensor records.")

/// A `MotionRecord` is a `Codable` implementation of `SampleRecord` that can be used
/// to record a sample from one of the core motion sensors or calculated vectors of the
/// `CMDeviceMotion` data object.
///
/// - example:
///
/// ```
///     // Example json for a codable record.
///        func testMotionRecord_Attitude() {
///            let json = """
///                {
///                    "timestamp" : 1.2498140833340585,
///                    "stepPath" : "Cardio Stair Step/heartRate.after/heartRate",
///                    "sensorType" : "attitude",
///                    "referenceCoordinate" : "North-West-Up",
///                    "heading" : 270.25,
///                    "eventAccuracy" : 4,
///                    "x" : 0.064788818359375,
///                    "y" : -0.1324615478515625,
///                    "z" : -0.9501953125,
///                    "w" : 1
///                }
///                """.data(using: .utf8)! // our data in native (JSON) format
/// ```
///
/// - seealso: "CodableMotionRecorderTests.swift" unit tests for additional examples.
public struct MotionRecord : SampleRecord, DelimiterSeparatedEncodable {

    /// System clock time.
    public let uptime: ClockUptime?

    /// Time that the system has been awake since last reboot.
    public let timestamp: SecondDuration?

    /// An identifier marking the current step.
    public var stepPath: String { _stepPath ?? "" }
    private let _stepPath: String?

    /// The date timestamp when the measurement was taken (if available).
    public let timestampDate: Date?

    /// The sensor type for this record sample.
    /// - note: If `nil` then this is a decoded log file marker used to mark step transitions.
    public let sensorType: MotionRecorderType?

    /// A number marking the sensor accuracy of the magnetic field sensor.
    public let eventAccuracy: Int?

    /// Used for an `attitude` record type to describe the reference frame.
    public let referenceCoordinate: AttitudeReferenceFrame?

    /// The heading angle in the range [0,360) degrees with respect to the CMAttitude reference frame.
    /// A negative value is returned for `CMAttitudeReferenceFrame.xArbitraryZVertical` and
    /// `CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical` reference coordinates.
    public let heading: Double?

    /// The `x` component of the vector measurement for this sensor sample.
    public let x: Double?

    /// The `y` component of the vector measurement for this sensor sample.
    public let y: Double?

    /// The `z` component of the vector measurement for this sensor sample.
    public let z: Double?

    /// The `w` component of the vector measurement for this sensor sample.
    /// Used by the attitude quaternion.
    public let w: Double?

    private enum CodingKeys : String, OrderedEnumCodingKey {
        case uptime, timestamp, _stepPath = "stepPath", timestampDate, sensorType, eventAccuracy, referenceCoordinate, heading, x, y, z, w
    }

    fileprivate init(uptime: ClockUptime?, timestamp: SecondDuration?, stepPath: String, timestampDate: Date?, sensorType: MotionRecorderType?, eventAccuracy: Int?, referenceCoordinate: AttitudeReferenceFrame?, heading: Double?, x: Double?, y: Double?, z: Double?, w: Double?) {
        self.uptime = uptime
        self.timestamp = timestamp
        self._stepPath = stepPath
        self.timestampDate = timestampDate
        self.sensorType = sensorType
        self.eventAccuracy = eventAccuracy
        self.referenceCoordinate = referenceCoordinate
        self.heading = heading
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }

    /// Initialize from a raw sensor data point.
    /// - parameters:
    ///     - startUptime: System clock uptime when the recorder was started.
    ///     - stepPath: The current step path.
    ///     - data: The raw sensor data to record.
    public init(stepPath: String, data: MotionVectorData, uptime: ClockUptime, timestamp: SecondDuration) {
        self._stepPath = stepPath
        self.uptime = uptime
        self.timestamp = timestamp
        self.timestampDate = nil
        self.heading = nil
        self.eventAccuracy = nil
        self.referenceCoordinate = nil
        self.w = nil

        self.sensorType = data.sensorType
        self.x = data.vector.x
        self.y = data.vector.y
        self.z = data.vector.z
    }
    
    #if os(iOS)

    /// Initialize from a `CMDeviceMotion` for a given sensor type or calculated vector.
    /// - parameters:
    ///     - startUptime: System clock uptime when the recorder was started.
    ///     - stepPath: The current step path.
    ///     - data: The `CMDeviceMotion` data sample from which to record information.
    ///     - referenceFrame: The `CMAttitudeReferenceFrame` for this recording.
    ///     - sensorType: The recorder type for which to record the vector.
    public init?(stepPath: String, data: CMDeviceMotion, referenceFrame: CMAttitudeReferenceFrame, sensorType: MotionRecorderType, uptime: ClockUptime, timestamp: SecondDuration) {

        var eventAccuracy: Int?
        var referenceCoordinate: AttitudeReferenceFrame?
        let vector: MotionVector
        var w: Double?
        var heading: Double?

        switch sensorType {
        case .attitude:
            vector = data.attitude.quaternion
            w = data.attitude.quaternion.w
            referenceCoordinate = AttitudeReferenceFrame(frame: referenceFrame)
            eventAccuracy = Int(data.magneticField.accuracy.rawValue)
            if #available(iOS 11.0, *) {
                heading = (data.heading >= 0) ? data.heading : nil
            }

        case .gravity:
            vector = data.gravity

        case .magneticField:
            vector = data.magneticField.field
            eventAccuracy = Int(data.magneticField.accuracy.rawValue)
            if #available(iOS 11.0, *) {
                heading = data.heading
            }

        case .rotationRate:
            vector = data.rotationRate

        case .userAcceleration:
            vector = data.userAcceleration

        default:
            return nil
        }

        self.uptime = uptime
        self.timestamp = timestamp
        self._stepPath = stepPath
        self.timestampDate = nil
        self.sensorType = sensorType
        self.eventAccuracy = eventAccuracy
        self.referenceCoordinate = referenceCoordinate
        self.x = vector.x
        self.y = vector.y
        self.z = vector.z
        self.w = w
        self.heading = heading
    }
    #endif
}

/// A string-value representation for the attitude reference frame.
public enum AttitudeReferenceFrame : String, Codable, CaseIterable, DocumentableStringEnum {

    /// Describes a reference frame in which the Z axis is vertical and the X axis points in
    /// an arbitrary direction in the horizontal plane.
    case xArbitraryZVertical = "Z-Up"

    /// Describes a reference frame in which the Z axis is vertical and the X axis points toward
    /// magnetic north.
    ///
    /// - note: Using this reference frame may require user interaction to calibrate the magnetometer.
    case xMagneticNorthZVertical = "North-West-Up"

    #if os(iOS)
    
    init(frame : CMAttitudeReferenceFrame) {
        switch frame {
        case .xMagneticNorthZVertical:
            self = .xMagneticNorthZVertical
        default:
            self = .xArbitraryZVertical
        }
    }
    
    #endif
    
    public static func allValues() -> [String] {
        AttitudeReferenceFrame.allCases.map { $0.rawValue }
    }
}

/// `MotionVector` is a convenience protocol for converting various CoreMotion sensor
/// values to a common schema.
public protocol MotionVector {
    var x: Double { get }
    var y: Double { get }
    var z: Double { get }
}

// `MotionVector` is a convenience protocol for converting various CoreMotion sensor
/// data to a common schema.
public protocol MotionVectorData {

    /// Time at which the item is valid. (clock uptime)
    var timestamp: TimeInterval { get }

    /// The vector associated with this motion sensor
    var vector: MotionVector { get }

    /// The raw motion sensor type.
    var sensorType: MotionRecorderType { get }
}

#if canImport(CoreMotion)

import CoreMotion

extension CMAcceleration : MotionVector {
}

extension CMRotationRate : MotionVector {
}

extension CMQuaternion : MotionVector {
}

extension CMMagneticField : MotionVector {
}

extension CMAccelerometerData : MotionVectorData {

    /// `self.acceleration`
    public var vector: MotionVector {
        return self.acceleration
    }

    /// `.accelerometer`
    public var sensorType: MotionRecorderType {
        return .accelerometer
    }
}

extension CMGyroData : MotionVectorData {

    /// `self.rotationRate`
    public var vector: MotionVector {
        return self.rotationRate
    }

    /// `.gyro`
    public var sensorType: MotionRecorderType {
        return .gyro
    }
}

extension CMMagnetometerData : MotionVectorData {

    /// `self.magneticField`
    public var vector: MotionVector {
        return self.magneticField
    }

    /// `.magnetometer`
    public var sensorType: MotionRecorderType {
        return .magnetometer
    }
}

#endif

// Documentation and Tests

extension MotionRecord : DocumentableStruct {
    public static func codingKeys() -> [CodingKey] {
        return CodingKeys.allCases
    }

    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        false
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
        case ._stepPath:
            return .init(propertyType: .primitive(.string), propertyDescription: "An identifier marking the current step.")
        case .timestampDate:
            return .init(propertyType: .format(.dateTime), propertyDescription: "The date timestamp when the measurement was taken (if available).")
        case .sensorType:
            return .init(propertyType: .reference(MotionRecorderType.documentableType()), propertyDescription: "The sensor type for this record sample.")
        case .eventAccuracy:
            return .init(propertyType: .primitive(.integer), propertyDescription: "A number marking the sensor accuracy of the magnetic field sensor.")
        case .referenceCoordinate:
            return .init(propertyType: .reference(AttitudeReferenceFrame.documentableType()), propertyDescription: "Used for an `attitude` record type to describe the reference frame.")
        case .heading:
            return .init(propertyType: .primitive(.number), propertyDescription: "The heading angle in the range [0,360) degrees with respect to the CMAttitude reference frame. A negative value is returned for `CMAttitudeReferenceFrame.xArbitraryZVertical` and `CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical` reference coordinates.")
        case .x:
            return .init(propertyType: .primitive(.number), propertyDescription: "The `x` component of the vector measurement for this sensor sample.")
        case .y:
            return .init(propertyType: .primitive(.number), propertyDescription: "The `y` component of the vector measurement for this sensor sample.")
        case .z:
            return .init(propertyType: .primitive(.number), propertyDescription: "The `z` component of the vector measurement for this sensor sample.")
        case .w:
            return .init(propertyType: .primitive(.number), propertyDescription: "The `w` component of the vector measurement for this sensor sample. Used by the attitude quaternion.")
        }
    }

    public static func examples() -> [MotionRecord] {

        let uptime = SystemClock.uptime()
        let timestamp = 0.0

        let gyro = MotionRecord(uptime: uptime, timestamp: timestamp, stepPath: "step1", timestampDate: nil, sensorType: .gyro, eventAccuracy: nil, referenceCoordinate: nil, heading: nil, x: 0.064788818359375, y: -0.1324615478515625, z: -0.9501953125, w: nil)
        let accelerometer = MotionRecord(uptime: uptime, timestamp: timestamp, stepPath: "step1", timestampDate: nil, sensorType: .accelerometer, eventAccuracy: nil, referenceCoordinate: nil, heading: nil, x: 0.064788818359375, y: -0.1324615478515625, z: -0.9501953125, w: nil)
        let magnetometer = MotionRecord(uptime: uptime, timestamp: timestamp, stepPath: "step1", timestampDate: nil, sensorType: .magnetometer, eventAccuracy: nil, referenceCoordinate: nil, heading: nil, x: 0.064788818359375, y: -0.1324615478515625, z: -0.9501953125, w: nil)
        let gravity = MotionRecord(uptime: uptime, timestamp: timestamp, stepPath: "step1", timestampDate: nil, sensorType: .gravity, eventAccuracy: nil, referenceCoordinate: nil, heading: nil, x: 0.064788818359375, y: -0.1324615478515625, z: -0.9501953125, w: nil)
        let userAccel = MotionRecord(uptime: uptime, timestamp: timestamp, stepPath: "step1", timestampDate: nil, sensorType: .userAcceleration, eventAccuracy: nil, referenceCoordinate: nil, heading: nil, x: 0.064788818359375, y: -0.1324615478515625, z: -0.9501953125, w: nil)
        let rotationRate = MotionRecord(uptime: uptime, timestamp: timestamp, stepPath: "step1", timestampDate: nil, sensorType: .userAcceleration, eventAccuracy: nil, referenceCoordinate: nil, heading: nil, x: 0.064788818359375, y: -0.1324615478515625, z: -0.9501953125, w: nil)
        let attitude = MotionRecord(uptime: uptime, timestamp: timestamp, stepPath: "step1", timestampDate: nil, sensorType: .attitude, eventAccuracy: nil, referenceCoordinate: .xArbitraryZVertical, heading: nil, x: 0.064788818359375, y: -0.1324615478515625, z: -0.9501953125, w: 1)
        let magneticField = MotionRecord(uptime: uptime, timestamp: timestamp, stepPath: "step1", timestampDate: nil, sensorType: .magneticField, eventAccuracy: 4, referenceCoordinate: nil, heading: 270, x: 0.064788818359375, y: -0.1324615478515625, z: -0.9501953125, w: 1)

        return [gyro, accelerometer, magnetometer, gravity, userAccel, rotationRate, attitude, magneticField]
    }
}
