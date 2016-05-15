//
// Created by Denis Dorokhov on 09/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import UIKit
import Localize_Swift

class CloudBootstrapLoginController: CloudBootstrapConfigControllerAbstract, UITextFieldDelegate {

    var authService: AuthService!

    @IBOutlet private var emailTextField: UITextField!
    @IBOutlet private var passwordTextField: UITextField!

    override func activate() {
        super.activate()

        emailTextField.text = ""
        passwordTextField.text = ""
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
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            passwordTextField.resignFirstResponder()
            authenticate()
        }
        return true
    }

    // MARK: Private

    @IBAction
    private func onLoginButtonTap() {
        authenticate()
    }

    @IBAction
    private func onOtherServerButtonTap() {
        delegate?.cloudBootstrapConfigControllerDidRequestOtherServer(self)
    }

    private func authenticate() {

        let credentials = Credentials(email: emailTextField.text ?? "", password: passwordTextField.text ?? "")

        startBackgroundActivity()

        authService.authenticate(credentials, onSuccess: {
            user in
            self.finishBackgroundActivity()
            self.delegate?.cloudBootstrapConfigControllerDidRequestBootstrap(self)
        }, onFailure: {
            self.finishBackgroundActivity()
            if Error.fetchFirstByCodes([Error.CODE_INVALID_CREDENTIALS], fromArray: $0) != nil {
                self.showCredentialsError()
            } else if Error.fetchFirstByCodes([Error.CODE_VALIDATION], fromArray: $0) != nil {
                self.showValidationError()
            } else {
                self.showConnectionError()
            }
        })
    }

    private func showValidationError() {
        errorNotifier.notify(Localized("Credentials are invalid."))
    }

    private func showCredentialsError() {
        errorNotifier.notify(Localized("Incorrect credentials, please check your email and password."))
    }

}
