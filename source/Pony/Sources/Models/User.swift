//
// Created by Denis Dorokhov on 30/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import ObjectMapper

enum Role: String {
    case User = "USER"
    case Admin = "ADMIN"
}

class User: Mappable {

    var id: Int64!

    var creationDate: NSDate!
    var updateDate: NSDate?

    var name: String!
    var email: String!

    var role: Role!

    init(id: Int64, creationDate: NSDate, updateDate: NSDate? = nil, name: String, email: String, role: Role) {
        self.id = id
        self.creationDate = creationDate
        self.updateDate = updateDate
        self.name = name
        self.email = email
        self.role = role
    }

    required init?(_ map: Map) {}

    func mapping(map: Map) {
        id <- (map["id"], Int64Transform())
        creationDate <- (map["creationDate"], DateTransform())
        updateDate <- (map["updateDate"], DateTransform())
        name <- map["name"]
        email <- map["email"]
        role <- map["role"]
    }
}
