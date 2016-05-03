//
// Created by Denis Dorokhov on 28/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import ObjectMapper

class ArtistAlbumsDto: Mappable {

    var artist: ArtistDto!
    var albums: [AlbumSongsDto]!

    init(artist: ArtistDto, albums: [AlbumSongsDto]) {
        self.artist = artist
        self.albums = albums
    }

    required init?(_ map: Map) {}

    func mapping(map: Map) {
        artist <- map["artist"]
        albums <- map["albums"]
    }
}
