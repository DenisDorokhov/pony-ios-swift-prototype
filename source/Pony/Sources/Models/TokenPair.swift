//
// Created by Denis Dorokhov on 26/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import ObjectMapper

class TokenPair: Mappable {

    private(set) var accessToken: String!
    private(set) var accessTokenExpiration: NSDate!

    private(set) var refreshToken: String!
    private(set) var refreshTokenExpiration: NSDate!

    init(accessToken: String, accessTokenExpiration: NSDate,
         refreshToken: String, refreshTokenExpiration: NSDate) {
        self.accessToken = accessToken
        self.accessTokenExpiration = accessTokenExpiration
        self.refreshToken = refreshToken
        self.refreshTokenExpiration = refreshTokenExpiration
    }

    convenience init(authentication: AuthenticationDto) {
        self.init(accessToken: authentication.accessToken!, accessTokenExpiration: authentication.accessTokenExpiration,
                refreshToken: authentication.refreshToken, refreshTokenExpiration: authentication.refreshTokenExpiration)
    }

    required init?(_ map: Map) {}

    func mapping(map: Map) {
        accessToken <- map["accessToken"]
        accessTokenExpiration <- (map["accessTokenExpiration"], DateTransform())
        refreshToken <- map["refreshToken"]
        refreshTokenExpiration <- (map["refreshTokenExpiration"], DateTransform())
    }
}
