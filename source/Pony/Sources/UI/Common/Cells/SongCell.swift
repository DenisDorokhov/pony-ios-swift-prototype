//
// Created by Denis Dorokhov on 15/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import UIKit
import Localize_Swift
import MRProgress

func ==(lhs: SongCell.State, rhs: SongCell.State) -> Bool {
    switch (lhs, rhs) {
    case (.Cloud, .Cloud):
        return true
    case (.Downloading(let progress1), .Downloading(let progress2)):
        return progress1 == progress2
    case (.Downloaded, .Downloaded):
        return true
    case (.Playing, .Playing):
        return true
    default:
        return false
    }
}

func !=(lhs: SongCell.State, rhs: SongCell.State) -> Bool {
    return !(lhs == rhs)
}

class SongCell: UITableViewCell {

    enum State {
        case Cloud
        case Downloading(Float)
        case Downloaded
        case Playing
    }

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

    var state: State = .Cloud {
        didSet {
            updateState()
        }
    }

    @IBOutlet private var trackNumberLabel: UILabel!
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var durationLabel: UILabel!
    @IBOutlet private var downloadImageView: UIImageView!
    @IBOutlet private var downloadProgressView: MRCircularProgressView!
    @IBOutlet private var downloadConstraints: [NSLayoutConstraint]!
    @IBOutlet private var playingImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        downloadProgressView.mayStop = true
        state = .Cloud
    }

    private func updateState() {
        trackNumberLabel.hidden = (state == .Playing)
        downloadImageView.hidden = (state != .Cloud)
        downloadProgressView.hidden = (state != .Downloading(0))
        playingImageView.hidden = (state != .Playing)
        if case let .Downloading(progress) = state {
            downloadProgressView.hidden = false
            downloadProgressView.progress = progress
        } else {
            downloadProgressView.hidden = true
        }
        if state == .Downloaded && state == .Playing {
            NSLayoutConstraint.deactivateConstraints(downloadConstraints)
        } else {
            NSLayoutConstraint.activateConstraints(downloadConstraints)
        }
    }

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
