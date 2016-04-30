//
// Created by Denis Dorokhov on 28/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import ObjectMapper

class AlbumDto: AbstractDto {

    var name: String?
    var year: Int?
    var artwork: Int64?
    var artworkUrl: String?
    var artist: ArtistDto?

    required init?(_ map: Map) {
        super.init(map)
    }

    override func mapping(map: Map) {
        super.mapping(map)

        name <- map["name"]
        year <- map["year"]
        artwork <- (map["artwork"], Int64Transform())
        artworkUrl <- map["artworkUrl"]
        artist <- map["artist"]
    }
}
