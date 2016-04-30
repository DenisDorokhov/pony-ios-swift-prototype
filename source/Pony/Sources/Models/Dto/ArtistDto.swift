//
// Created by Denis Dorokhov on 28/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import ObjectMapper

class ArtistDto: AbstractDto {

    var name: String?
    var artwork: Int?
    var artworkUrl: String?

    override func mapping(map: Map) {
        super.mapping(map)

        name <- map["name"]
        artwork <- map["artwork"]
        artworkUrl <- map["artworkUrl"]
    }
}
