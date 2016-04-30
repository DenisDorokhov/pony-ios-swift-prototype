//
// Created by Denis Dorokhov on 28/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import ObjectMapper

class AbstractDto: Mappable {

    var id: Int?

    required init?(_ map: Map) {}

    func mapping(map: Map) {
        id <- map["id"]
    }
}
