//
// Created by Denis Dorokhov on 02/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import RealmSwift

class GenreRealm: AbstractRealm {

    dynamic var name: String?

    let artwork = RealmOptional<Int64>()
}
