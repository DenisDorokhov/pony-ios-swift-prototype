//
// Created by Denis Dorokhov on 28/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import ObjectMapper

class AlbumDto: AbstractDto {

    var name: String?
    var year: Int?
    var artwork: Int?
    var artworkUrl: String?
    var artist: ArtistDto?

    override func mapping(map: Map) {
        super.mapping(map)

        name <- map["name"]
        year <- map["year"]
        artwork <- map["artwork"]
        artworkUrl <- map["artworkUrl"]
        artist <- map["artist"]
    }
}
