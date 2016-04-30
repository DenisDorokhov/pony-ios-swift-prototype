//
// Created by Denis Dorokhov on 28/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import ObjectMapper

class SongDto: AbstractDto {

    var updateDate: NSDate?

    var url: String?

    var size: Int?

    var duration: Int?
    var discNumber: Int?
    var trackNumber: Int?

    var artistName: String?
    var name: String?

    var album: AlbumDto?
    var genre: GenreDto?

    override func mapping(map: Map) {
        super.mapping(map)

        updateDate <- (map["name"], DateTransform())
        url <- map["url"]
        size <- map["size"]
        duration <- map["duration"]
        discNumber <- map["discNumber"]
        trackNumber <- map["trackNumber"]
        artistName <- map["artistName"]
        name <- map["name"]
        album <- map["album"]
        genre <- map["genre"]
    }
}