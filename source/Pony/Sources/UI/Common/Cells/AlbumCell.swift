//
// Created by Denis Dorokhov on 15/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import UIKit
import Localize_Swift

protocol AlbumCellDelegate: class {
    func albumCellDidRequestDownload(albumCell: AlbumCell)
}

class AlbumCell: UITableViewCell {

    weak var delegate: AlbumCellDelegate?

    var albumSongs: AlbumSongs? {
        didSet {
            nameLabel.text = albumSongs?.album.name ?? Localized("Unknown")
            if let year = albumSongs?.album.year {
                yearLabel.text = String(year)
            } else {
                yearLabel.text = nil
            }
            artworkLoaderView.url = albumSongs?.album.artworkUrl
        }
    }

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var yearLabel: UILabel!
    @IBOutlet var artworkLoaderView: ImageLoaderView!

    @IBAction
    func onButtonTap() {
        delegate?.albumCellDidRequestDownload(self)
    }
}
