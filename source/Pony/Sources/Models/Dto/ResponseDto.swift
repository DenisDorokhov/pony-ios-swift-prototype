//
// Created by Denis Dorokhov on 30/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import ObjectMapper

class ResponseDto {

    var version: String!
    var successful: Bool!
    var errors: [ErrorDto]!

    required init?(_ map: Map) {}

    func mapping(map: Map) {
        version <- map["version"]
        successful <- map["successful"]
        errors <- map["errors"]
    }
}

class ObjectResponseDto<T: Mappable>: ResponseDto, Mappable {

    var data: T?

    required init?(_ map: Map) {
        super.init(map)
    }

    override func mapping(map: Map) {
        super.mapping(map)

        data <- map["data"]
    }
}

class ArrayResponseDto<T: Mappable>: ResponseDto, Mappable {

    var data: [T]?

    required init?(_ map: Map) {
        super.init(map)
    }

    override func mapping(map: Map) {
        super.mapping(map)

        data <- map["data"]
    }
}
