//
// Created by Denis Dorokhov on 15/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import UIKit
import Localize_Swift

class SongCell: UITableViewCell {

    var song: Song? {
        didSet {
            if let trackNumber = song?.trackNumber {
                trackNumberLabel.text = String(trackNumber)
            } else {
                trackNumberLabel.text = nil
            }
            nameLabel.text = song?.name ?? Localized("Unknown")
            durationLabel.text = song?.formattedDuration
        }
    }

    @IBOutlet private var trackNumberLabel: UILabel!
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var durationLabel: UILabel!

}

class DiscSongCell: SongCell {

    override var song: Song? {
        didSet {
            let discNumber = song?.discNumber ?? 1
            discNumberLabel.text = Localized("Disc %d", arguments: discNumber >= 1 ? discNumber : 1)
        }
    }

    @IBOutlet private var discNumberLabel: UILabel!

}
