//
// Created by Denis Dorokhov on 09/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import UIKit
import Localize_Swift

protocol CloudBootstrapChildController: class {
    var active: Bool { get set }
}

protocol CloudBootstrapConfigControllerDelegate: class {
    func cloudBootstrapConfigControllerDidStartBackgroundActivity(configController: CloudBootstrapConfigController)
    func cloudBootstrapConfigControllerDidFinishBackgroundActivity(configController: CloudBootstrapConfigController)
    func cloudBootstrapConfigControllerDidRequestBootstrap(configController: CloudBootstrapConfigController)
    func cloudBootstrapConfigControllerDidRequestOtherServer(configController: CloudBootstrapConfigController)
}

protocol CloudBootstrapConfigController: CloudBootstrapChildController {
    var delegate: CloudBootstrapConfigControllerDelegate? { get set }
}

class CloudBootstrapChildControllerAbstract: UIViewController, CloudBootstrapChildController {

    var active: Bool = false {
        didSet {
            if active != oldValue {
                if active {
                    activate()
                } else {
                    passivate()
                }
            }
        }
    }

    func activate() {}
    func passivate() {}
}

class CloudBootstrapConfigControllerAbstract: CloudBootstrapChildControllerAbstract, CloudBootstrapConfigController {

    var errorNotifier: ErrorNotifier!

    weak var delegate: CloudBootstrapConfigControllerDelegate?

    func startBackgroundActivity() {
        delegate?.cloudBootstrapConfigControllerDidStartBackgroundActivity(self)
    }

    func finishBackgroundActivity() {
        delegate?.cloudBootstrapConfigControllerDidFinishBackgroundActivity(self)
    }

    func showConnectionError() {
        errorNotifier.notify(Localized("Could not connect to server, please check your server URL."))
    }

    func showOfflineError() {
        errorNotifier.notify(Localized("Could not connect to server, are you online?"))
    }
}

class CloudBootstrapController: UIViewController, CloudBootstrapServiceDelegate, CloudBootstrapConfigControllerDelegate, CloudBootstrapRetryControllerDelegate {

    var cloudBootstrapService: CloudBootstrapService!

    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private var scrollView: UIScrollView!

    private var serverConfigController: CloudBootstrapServerController!
    private var loginConfigController: CloudBootstrapLoginController!
    private var retryController: CloudBootstrapRetryController!

    private var currentChildController: CloudBootstrapChildControllerAbstract? {
        didSet {
            if let oldController = oldValue {
                oldController.active = false
                hideView(oldController.view.superview!)
            }
            if let currentChildController = currentChildController {
                currentChildController.active = true
                showView(currentChildController.view.superview!)
            }
        }
    }

    private var backgroundActivityStarted: Bool = false {
        didSet {
            if backgroundActivityStarted != oldValue {
                if backgroundActivityStarted {
                    showView(activityIndicator)
                } else {
                    hideView(activityIndicator)
                }
            }
        }
    }

    deinit {
        cloudBootstrapService.removeDelegate(self)
        Notifications.unsubscribe(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        cloudBootstrapService.addDelegate(self)

        serverConfigController!.delegate = self
        loginConfigController!.delegate = self
        retryController!.delegate = self

        activityIndicator.alpha = 0

        serverConfigController.view.superview!.alpha = 0
        loginConfigController.view.superview!.alpha = 0
        retryController.view.superview!.alpha = 0

        activityIndicator.startAnimating()

        Notifications.subscribe(UIKeyboardDidShowNotification, self) {
            [weak self] notification in
            let keyboardFrameValue = notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue
            let keyboardSize = keyboardFrameValue?.CGRectValue().size ?? CGSizeZero
            let inset = UIEdgeInsetsMake(0, 0, keyboardSize.height, 0)
            self?.scrollView.contentInset = inset
            self?.scrollView.scrollIndicatorInsets = inset
        }
        Notifications.subscribe(UIKeyboardWillHideNotification, self) {
            [weak self] notification in
            self?.scrollView.contentInset = UIEdgeInsetsZero
            self?.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        cloudBootstrapService.bootstrap()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        if segue.destinationViewController is CloudBootstrapServerController {
            serverConfigController = segue.destinationViewController as! CloudBootstrapServerController
        } else if segue.destinationViewController is CloudBootstrapLoginController {
            loginConfigController = segue.destinationViewController as! CloudBootstrapLoginController
        } else if segue.destinationViewController is CloudBootstrapRetryController {
            retryController = segue.destinationViewController as! CloudBootstrapRetryController
        }
    }

    @IBAction
    func unwindCloudBootstrapFromCloudArtists(segue: UIStoryboardSegue) {
        // Do nothing.
    }

    // MARK: CloudBootstrapServiceDelegate

    func cloudBootstrapServiceDidStartBootstrap(cloudBootstrapService: CloudBootstrapService) {
        currentChildController = nil
    }

    func cloudBootstrapServiceDidFinishBootstrap(cloudBootstrapService: CloudBootstrapService) {
        backgroundActivityStarted = false
        performSegueWithIdentifier("cloudBootstrapToCloudArtists", sender: self)
    }

    func cloudBootstrapServiceDidStartBackgroundActivity(cloudBootstrapService: CloudBootstrapService) {
        backgroundActivityStarted = true
    }

    func cloudBootstrapServiceDidRequireRestUrl(cloudBootstrapService: CloudBootstrapService) {
        backgroundActivityStarted = false
        currentChildController = serverConfigController
    }

    func cloudBootstrapServiceDidRequireAuthentication(cloudBootstrapService: CloudBootstrapService) {
        backgroundActivityStarted = false
        currentChildController = loginConfigController
    }

    func cloudBootstrapService(cloudBootstrapService: CloudBootstrapService, didFailWithErrors errors: [Error]) {
        backgroundActivityStarted = false
        currentChildController = retryController
    }

    // MARK: CloudBootstrapConfigControllerDelegate

    func cloudBootstrapConfigControllerDidStartBackgroundActivity(configController: CloudBootstrapConfigController) {
        backgroundActivityStarted = true
    }

    func cloudBootstrapConfigControllerDidFinishBackgroundActivity(configController: CloudBootstrapConfigController) {
        backgroundActivityStarted = false
    }

    func cloudBootstrapConfigControllerDidRequestBootstrap(configController: CloudBootstrapConfigController) {
        cloudBootstrapService.bootstrap()
    }

    func cloudBootstrapConfigControllerDidRequestOtherServer(configController: CloudBootstrapConfigController) {
        backgroundActivityStarted = false
        cloudBootstrapService.clearBootstrapData()
        cloudBootstrapService.bootstrap()
    }

    // MARK: CloudBootstrapRetryControllerDelegate

    func cloudBootstrapRetryControllerDidRequestRetry(retryController: CloudBootstrapRetryController) {
        cloudBootstrapService.bootstrap()
    }

    func cloudBootstrapRetryControllerDidRequestOtherServer(retryController: CloudBootstrapRetryController) {
        currentChildController = nil
        cloudBootstrapService.clearBootstrapData()
        cloudBootstrapService.bootstrap()
    }

    // MARK: Private

    private func hideView(view: UIView) {
        UIView.animateWithDuration(0.3, delay: 0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
            view.alpha = 0
        }, completion: nil)
    }

    private func showView(view: UIView) {
        UIView.animateWithDuration(0.3, delay: 0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
            view.alpha = 1
        }, completion: nil)
    }

}
