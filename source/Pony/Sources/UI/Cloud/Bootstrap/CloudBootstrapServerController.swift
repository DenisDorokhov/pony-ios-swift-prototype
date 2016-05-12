//
// Created by Denis Dorokhov on 09/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import UIKit
import Localize_Swift
import Regex

class CloudBootstrapServerController: CloudBootstrapConfigControllerAbstract {

    var restUrlDao: RestUrlDao!
    var restService: RestService!

    @IBOutlet private var serverTextField: UITextField!
    @IBOutlet private var httpsSwitch: UISwitch!

    override func activate() {
        super.activate()
        let url = restUrlDao.fetchUrl()
        serverTextField.text = urlToString(url)
        httpsSwitch.on = (url?.scheme == "https")
    }

    override func startBackgroundActivity() {
        super.startBackgroundActivity()
        view.userInteractionEnabled = false
    }

    override func finishBackgroundActivity() {
        super.finishBackgroundActivity()
        view.userInteractionEnabled = true
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == serverTextField {
            serverTextField.resignFirstResponder()
            save()
        }
        return true
    }

    // MARK: Private

    @IBAction
    private func onSaveButtonTap() {
        save()
    }

    func save() {
        let urlString = formToUrl()
        if let url = NSURL(string: urlString) where validateUrl(urlString) {
            restUrlDao.storeUrl(url)
            startBackgroundActivity()
            restService.getInstallation(onSuccess: {
                installation in
                self.finishBackgroundActivity()
                self.delegate?.cloudBootstrapConfigControllerDidRequestBootstrap(self)
            }, onFailure: {
                errors in
                self.finishBackgroundActivity()
                self.restUrlDao.removeUrl()
                if Error.fetchFirstByCodes([Error.CODE_CLIENT_OFFLINE], fromArray: errors) == nil {
                    self.showConnectionError()
                } else {
                    self.showOfflineError()
                }
            })
        } else {
            showValidationError()
        }
    }

    func showValidationError() {
        errorNotifier.notify(Localized("Server URL is invalid."))
    }

    func urlToString(url: NSURL?) -> String {
        if let url = url {
            var result = url.host ?? ""
            let isStandardHttp = (url.scheme == "http" && url.port == 80)
            let isStandardHttpSecure = (url.scheme == "https" && url.port == 443)
            if !isStandardHttp && !isStandardHttpSecure {
                result += ":\(url.port)"
            }
            result += url.path ?? ""
            return result
        }
        return ""
    }

    func formToUrl() -> String {
        var urlString = httpsSwitch.on ? "https://" : "http://"
        urlString += serverTextField.text ?? ""
        return urlString
    }

    func validateUrl(url: String) -> Bool {
        return Regex("^http(s)?://([\\w-]+\\.)+[\\w-]+(/[\\w- ./?%&amp;=]*)?$").matches(url)
    }

}
