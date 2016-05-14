//
// Created by Denis Dorokhov on 14/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import UIKit
import Swinject
import XCGLogger

@IBDesignable
class ImageLoadView: UIView {

    private let log: XCGLogger = XCGLogger.defaultInstance()

    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!

    @IBInspectable private var emptyImage: UIImage? = UIImage(named: "image-empty")
    @IBInspectable private var errorImage: UIImage? = UIImage(named: "image-error")

    private let restService = SwinjectStoryboard.defaultContainer.resolve(RestService.self)

    private var currentRequest: RestRequest?

    var url: String? {
        didSet {
            updateUrl()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: String(self.dynamicType), bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        for direction in ["H", "V"] {
            addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(direction + ":|[view]|",
                    options: [], metrics: nil, views: ["view": view]))
        }
        imageView.image = emptyImage
        imageView.hidden = false
        imageView.layer.minificationFilter = kCAFilterTrilinear
        activityIndicator.hidden = true
    }

    private func updateUrl() {
        currentRequest?.cancel()
        currentRequest = nil
        if let url = url, restService = restService {
            imageView.image = nil
            imageView.hidden = true
            activityIndicator.hidden = false
            activityIndicator.startAnimating()
            currentRequest = restService.downloadImage(url, onSuccess: {
                self.currentRequest = nil
                self.imageView.image = $0
                self.imageView.hidden = false
                self.activityIndicator.hidden = true
            }, onFailure: {
                if Error.fetchFirstByCodes([Error.CODE_CLIENT_REQUEST_CANCELLED], fromArray: $0) == nil {
                    self.currentRequest = nil
                    self.log.warning("Could not load image '\(url)': \($0)")
                    self.imageView.image = self.errorImage
                    self.imageView.hidden = false
                    self.activityIndicator.hidden = true
                }
            })
        } else {
            imageView.image = emptyImage
            imageView.hidden = false
            activityIndicator.hidden = true
        }
    }
}
