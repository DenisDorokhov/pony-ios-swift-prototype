//
// Created by Denis Dorokhov on 12/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import UIKit
import Localize_Swift

class ArtistCell: UITableViewCell {

    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var imageLoadView: ImageLoadView!

    var artist: Artist? {
        didSet {
            nameLabel.text = artist?.name ?? Localized("Unknown")
            imageLoadView.url = artist?.artworkUrl
        }
    }

}
