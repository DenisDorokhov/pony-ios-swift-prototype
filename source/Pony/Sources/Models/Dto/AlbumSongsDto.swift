//
// Created by Denis Dorokhov on 29/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import ObjectMapper

class AlbumSongsDto: Mappable {

    var album: AlbumDto!
    var songs: [SongDto]!

    init(album: AlbumDto, songs: [SongDto]) {
        self.album = album
        self.songs = songs
    }

    required init?(_ map: Map) {}

    func mapping(map: Map) {
        album <- map["album"]
        songs <- map["songs"]
    }
}
