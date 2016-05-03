//
// Created by Denis Dorokhov on 28/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import ObjectMapper

class GenreDto: AbstractDto {

    var name: String?
    var artwork: Int64?
    var artworkUrl: String?

    override init(id: Int64) {
        super.init(id: id)
    }

    required init?(_ map: Map) {
        super.init(map)
    }

    override func mapping(map: Map) {
        super.mapping(map)

        name <- map["name"]
        artwork <- (map["artwork"], Int64Transform())
        artworkUrl <- map["artworkUrl"]
    }
}
