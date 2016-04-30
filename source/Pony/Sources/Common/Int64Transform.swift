//
// Created by Denis Dorokhov on 30/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import ObjectMapper

class Int64Transform: TransformType {

    typealias Object = Int64
    typealias JSON = NSNumber

    init() {}

    func transformFromJSON(value: AnyObject?) -> Int64? {
        if let number = value as? NSNumber {
            return number.longLongValue
        }
        return nil
    }

    func transformToJSON(value: Int64?) -> NSNumber? {
        if let number = value {
            return NSNumber(longLong: number)
        }
        return nil
    }
}
