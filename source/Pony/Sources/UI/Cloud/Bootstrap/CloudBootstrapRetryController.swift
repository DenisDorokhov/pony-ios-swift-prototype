//
// Created by Denis Dorokhov on 09/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import UIKit

protocol CloudBootstrapRetryControllerDelegate: class {
    func cloudBootstrapRetryControllerDidRequestRetry(retryController: CloudBootstrapRetryController)
    func cloudBootstrapRetryControllerDidRequestOtherServer(retryController: CloudBootstrapRetryController)
}

class CloudBootstrapRetryController: CloudBootstrapChildControllerAbstract {

    weak var delegate: CloudBootstrapRetryControllerDelegate?

    @IBAction
    private func onRetryButtonTap() {
        delegate?.cloudBootstrapRetryControllerDidRequestRetry(self)
    }

    @IBAction
    private func onOtherServerButtonTap() {
        delegate?.cloudBootstrapRetryControllerDidRequestOtherServer(self)
    }

}
