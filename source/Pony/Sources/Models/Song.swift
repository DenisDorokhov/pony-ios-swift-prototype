//
// Created by Denis Dorokhov on 28/04/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import ObjectMapper

class Song: Mappable, Hashable {

    var id: Int64!
    var updateDate: NSDate?

    var url: String!

    var size: Int64!

    var duration: Int!
    var discNumber: Int?
    var trackNumber: Int?

    var artistName: String?
    var name: String?

    var album: Album!
    var genre: Genre!

    var formattedDuration: String {
        let formatter = NSDateComponentsFormatter()
        formatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehavior.Pad
        formatter.unitsStyle = .Positional
        if duration > 60 * 60 {
            formatter.allowedUnits = [NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second]
        } else {
            formatter.allowedUnits = [NSCalendarUnit.Minute, NSCalendarUnit.Second]
        }
        return formatter.stringFromTimeInterval(NSTimeInterval(duration)) ?? ""
    }

    init(id: Int64, url: String, size: Int64, duration: Int, album: Album, genre: Genre) {
        self.id = id
        self.url = url
        self.size = size
        self.duration = duration
        self.album = album
        self.genre = genre
    }

    required init?(_ map: Map) {}

    func mapping(map: Map) {
        id <- (map["id"], Int64Transform())
        updateDate <- (map["name"], DateTransform())
        url <- map["url"]
        size <- (map["size"], Int64Transform())
        duration <- map["duration"]
        discNumber <- map["discNumber"]
        trackNumber <- map["trackNumber"]
        artistName <- map["artistName"]
        name <- map["name"]
        album <- map["album"]
        genre <- map["genre"]
    }

    var hashValue: Int {
        return id.hashValue
    }
}

func ==(lhs: Song, rhs: Song) -> Bool {
    return lhs.id == rhs.id
}
