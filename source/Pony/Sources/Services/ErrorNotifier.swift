//
// Created by Denis Dorokhov on 10/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import UIKit
import Localize_Swift

class ErrorNotifier {

    func notify(text: String, executeOnRetry: (() -> Void)? = nil) {

        let window = UIWindow(frame: UIScreen.mainScreen().bounds)

        window.windowLevel = UIWindowLevelAlert

        let alertController = UIAlertController(title: Localized("Error"), message: text, preferredStyle: UIAlertControllerStyle.Alert)

        alertController.addAction(UIAlertAction(title: Localized("OK"), style: UIAlertActionStyle.Default) {
            action in
            window.hidden = true
        })

        if executeOnRetry != nil {
            alertController.addAction(UIAlertAction(title: Localized("Retry"), style: UIAlertActionStyle.Cancel) {
                action in
                window.hidden = true
                executeOnRetry?()
            })
        }

        window.rootViewController = UIViewController()
        window.tintColor = UIApplication.sharedApplication().delegate?.window??.rootViewController?.view.tintColor
        window.makeKeyAndVisible()
        window.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
    }
}
