//
// Created by Denis Dorokhov on 30/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import ObjectMapper

enum RoleDto: String {
    case User = "USER"
    case Admin = "ADMIN"
}

class UserDto: AbstractDto {

    var creationDate: NSDate?
    var updateDate: NSDate?

    var name: String?
    var email: String?

    var role: RoleDto?

    required init?(_ map: Map) {
        super.init(map)
    }

    override func mapping(map: Map) {
        super.mapping(map)

        creationDate <- (map["creationDate"], DateTransform())
        updateDate <- (map["updateDate"], DateTransform())
        name <- map["name"]
        email <- map["email"]
        role <- map["role"]
    }
}
