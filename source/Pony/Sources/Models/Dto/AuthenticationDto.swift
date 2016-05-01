//
// Created by Denis Dorokhov on 29/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import ObjectMapper

class AuthenticationDto: Mappable {

    var accessToken: String!
    var accessTokenExpiration: NSDate!

    var refreshToken: String!
    var refreshTokenExpiration: NSDate!

    var user: UserDto!

    init(accessToken: String, accessTokenExpiration: NSDate,
         refreshToken: String, refreshTokenExpiration: NSDate,
         user: UserDto) {
        self.accessToken = accessToken
        self.accessTokenExpiration = accessTokenExpiration
        self.refreshToken = refreshToken
        self.refreshTokenExpiration = refreshTokenExpiration
        self.user = user
    }

    required init?(_ map: Map) {}

    func mapping(map: Map) {
        accessToken <- map["accessToken"]
        accessTokenExpiration <- (map["accessTokenExpiration"], DateTransform())
        refreshToken <- map["refreshToken"]
        refreshTokenExpiration <- (map["refreshTokenExpiration"], DateTransform())
        user <- map["user"]
    }
}
