//
// Created by Denis Dorokhov on 26/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import ObjectMapper
import KeychainSwift
import XCGLogger

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

    convenience init(authentication: Authentication) {
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

protocol TokenPairDao: class {
    func fetchTokenPair() -> TokenPair?
    func storeTokenPair(tokenPair: TokenPair)
    func removeTokenPair()
}

class TokenPairDaoImpl: TokenPairDao {

    let KEY_TOKEN_PAIR = "TokenDataDao.tokenPair"

    /**
     * When NSUserDefaults value for this key does not exists, no token data will be fetched.
     * This behavior is implemented to avoid token fetching when the application was uninstalled.
     */
    let KEY_HAS_TOKEN = "TokenPairDao.hasToken"

    let log = XCGLogger.defaultInstance()
    let keychain = KeychainSwift()

    func fetchTokenPair() -> TokenPair? {

        var tokenPair: TokenPair?

        if let tokenPairJson = keychain.get(KEY_TOKEN_PAIR) {

            tokenPair = Mapper<TokenPair>().map(tokenPairJson)

            if !NSUserDefaults.standardUserDefaults().boolForKey(KEY_HAS_TOKEN) {
                log.debug("It seems like application was uninstalled. Removing the token.")
                removeTokenPair()
                tokenPair = nil
            }
        }

        return tokenPair
    }

    func storeTokenPair(tokenPair: TokenPair) {

        keychain.set(Mapper().toJSONString(tokenPair)!, forKey: KEY_TOKEN_PAIR)

        NSUserDefaults.standardUserDefaults().setBool(true, forKey: KEY_HAS_TOKEN)
        NSUserDefaults.standardUserDefaults().synchronize()

        log.verbose("Token pair stored.")
    }

    func removeTokenPair() {

        keychain.delete(KEY_TOKEN_PAIR)

        NSUserDefaults.standardUserDefaults().removeObjectForKey(KEY_HAS_TOKEN)
        NSUserDefaults.standardUserDefaults().synchronize()

        log.verbose("Token pair removed.")
    }
}

class TokenPairDaoCached: TokenPairDao {

    let tokenPairDao: TokenPairDao

    var cachedTokenPair: TokenPair?
    var isCachedTokenPairNil: Bool = false

    init(tokenPairDao: TokenPairDao) {
        self.tokenPairDao = tokenPairDao
    }

    func fetchTokenPair() -> TokenPair? {

        if isCachedTokenPairNil {
            return nil
        }
        if cachedTokenPair != nil {
            return cachedTokenPair
        }

        cachedTokenPair = tokenPairDao.fetchTokenPair()
        isCachedTokenPairNil = (cachedTokenPair == nil)

        return cachedTokenPair
    }

    func storeTokenPair(tokenPair: TokenPair) {

        tokenPairDao.storeTokenPair(tokenPair)

        cachedTokenPair = tokenPair
        isCachedTokenPairNil = false
    }

    func removeTokenPair() {

        tokenPairDao.removeTokenPair()

        cachedTokenPair = nil
        isCachedTokenPairNil = true
    }
}
