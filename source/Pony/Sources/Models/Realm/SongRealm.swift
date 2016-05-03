//
// Created by Denis Dorokhov on 02/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import RealmSwift

class SongRealm: AbstractRealm {

    dynamic var updateDate: NSDate?

    dynamic var size: Int64 = 0

    dynamic var duration: Int = 0
    let discNumber = RealmOptional<Int>()
    let trackNumber = RealmOptional<Int>()

    dynamic var artistName: String?
    dynamic var name: String?

    dynamic var album: AlbumRealm!
    dynamic var genre: GenreRealm!
}
