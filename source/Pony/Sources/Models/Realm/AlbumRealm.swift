//
// Created by Denis Dorokhov on 02/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import RealmSwift

class AlbumRealm: AbstractRealm {

    dynamic var name: String?

    let year = RealmOptional<Int>()
    let artwork = RealmOptional<Int64>()

    dynamic var artist: ArtistRealm!

    let songs = LinkingObjects(fromType: SongRealm.self, property: "album")
}