//
// Created by Denis Dorokhov on 28/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation

@testable import Pony

class TokenPairDaoMock: TokenPairDao {

    var tokenPair: TokenPair?

    private(set) var fetchTokenPairCallsCount: Int = 0

    init(tokenPair: TokenPair?) {
        self.tokenPair = tokenPair
    }

    convenience init() {
        self.init(tokenPair: nil)
    }

    func fetchTokenPair() -> TokenPair? {

        fetchTokenPairCallsCount += 1

        return tokenPair
    }

    func storeTokenPair(tokenPair: TokenPair) {
        self.tokenPair = tokenPair
    }

    func removeTokenPair() {
        tokenPair = nil
    }
}
