//
//  LDChangedFlag.swift
//  Darkly
//
//  Created by Mark Pokorny on 8/18/17. +JMJ
//  Copyright © 2017 LaunchDarkly. All rights reserved.
//

import Foundation

/**
 Collects the elements of a feature flag that changed as a result of a `clientstream` update or feature flag request. The SDK will pass a LDChangedFlag or a collection of LDChangedFlags into feature flag observer closures. The client app will have to convert the old/newValue into the expected type. See `LDClient.observe(key:owner:handler:)`, `LDClient.observe(keys:owner:handler:)`, and `LDClient.observeAll(owner:handler:)` for more details.
 */
public struct LDChangedFlag {
    ///The key of the changed feature flag
    public let key: LDFlagKey
    ///The feature flag's value before the change
    public let oldValue: Any?
    ///The feature flag value's source before the change
    public let oldValueSource: LDFlagValueSource?
    ///The feature flag's value after the change
    public let newValue: Any?
    ///The feature flag value's source after the change
    public let newValueSource: LDFlagValueSource?
    
    init(key: LDFlagKey, oldValue: Any?, oldValueSource: LDFlagValueSource?, newValue: Any?, newValueSource: LDFlagValueSource?) {
        self.key = key
        self.oldValue = oldValue
        self.oldValueSource = oldValueSource
        self.newValue = newValue
        self.newValueSource = newValueSource
    }
}
