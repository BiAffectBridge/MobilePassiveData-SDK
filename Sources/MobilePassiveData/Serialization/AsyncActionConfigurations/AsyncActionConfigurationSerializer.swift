//
//  AsyncActionConfigurationSerializer.swift
//
//

import Foundation
import JsonModel


/// `AsyncActionType` is an extendable string enum used by the `SerializationFactory` to
/// create the appropriate result type.
public struct AsyncActionType : TypeRepresentable, Codable, Hashable {

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Motion Recorder Configuration.
    public static let motion: AsyncActionType = "motion"
    
    /// Weather Services Configuration
    public static let weather: AsyncActionType = "weather"
    
    /// List of all the standard types.
    public static func allStandardTypes() -> [AsyncActionType] {
        [.motion, .weather]
    }
}

extension AsyncActionType : ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

extension AsyncActionType : DocumentableStringLiteral {
    public static func examples() -> [String] {
        return allStandardTypes().map{ $0.rawValue }
    }
}

/// `SerializableAsyncActionConfiguration` is the base implementation for `AsyncActionConfiguration`
/// that is serialized using the `Codable` protocol and the polymorphic serialization defined by
/// this framework.
public protocol SerializableAsyncActionConfiguration : AsyncActionConfiguration, PolymorphicRepresentable, Encodable {
    var asyncActionType: AsyncActionType { get }
}

extension SerializableAsyncActionConfiguration {
    public var typeName: String { asyncActionType.stringValue }
}

public final class AsyncActionConfigurationSerializer : GenericPolymorphicSerializer<AsyncActionConfiguration>, DocumentableInterface {
    public var documentDescription: String? {
        """
        `AsyncActionConfiguration` defines general configuration for an asynchronous action
        that should be run in the background. Depending upon the parameters and how the action is set
        up, this could be something that is run continuously or else is paused or reset based on a
        timeout interval.
        """.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "  ", with: "\n")
    }
    
    public var jsonSchema: URL {
        URL(string: "\(self.interfaceName).json", relativeTo: kBaseJsonSchemaURL)!
    }

    override init() {
        super.init([
            MotionRecorderConfigurationObject.examples().first!,
            WeatherConfigurationObject.examples().first!,
        ])
    }
}
