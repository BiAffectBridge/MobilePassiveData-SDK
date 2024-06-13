//
//  MobilePassiveDataFactory.swift
//  

import Foundation
import JsonModel
import ResultModel

/// `MobilePassiveDataFactory` is a subclass of the `ResultDataFactory` that registers a serializer
/// for `AsyncActionConfiguration` objects that can be used to deserialize the results.
open class MobilePassiveDataFactory : ResultDataFactory {

    public let asyncActionSerializer = AsyncActionConfigurationSerializer()

    public required init() {
        super.init()
        self.registerSerializer(asyncActionSerializer)
        
        // Add weather results
        self.resultSerializer.add(WeatherResult())
        
        // Add root documentables
        self.registerRootObject(motionRecordSchema)
        self.registerRootObject(WeatherResult())
    }
}
