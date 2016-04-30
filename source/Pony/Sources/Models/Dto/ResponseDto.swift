//
// Created by Denis Dorokhov on 30/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import ObjectMapper

class ResponseDto<T: Mappable>: Mappable {

    var version: String?
    var successful: Bool?
    var errors: [ErrorDto]?
    var data: T?

    required init?(_ map: Map) {}

    func mapping(map: Map) {
        version <- map["version"]
        successful <- map["successful"]
        errors <- map["errors"]
        data <- map["data"]
    }
}
