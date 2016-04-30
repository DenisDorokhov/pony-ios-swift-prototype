//
// Created by Denis Dorokhov on 30/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import ObjectMapper

class AbstractResponseDto {
    var version: String?
    var successful: Bool?
    var errors: [ErrorDto]?
}

class ObjectResponseDto<T: Mappable>: AbstractResponseDto, Mappable {

    var data: T?

    required init?(_ map: Map) {}

    func mapping(map: Map) {
        version <- map["version"]
        successful <- map["successful"]
        errors <- map["errors"]
        data <- map["data"]
    }
}

class ArrayResponseDto<T: Mappable>: AbstractResponseDto, Mappable {

    var data: [T]?

    required init?(_ map: Map) {}

    func mapping(map: Map) {
        version <- map["version"]
        successful <- map["successful"]
        errors <- map["errors"]
        data <- map["data"]
    }
}
