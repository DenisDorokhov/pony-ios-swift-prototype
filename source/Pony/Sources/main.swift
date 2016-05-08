//
// Created by Denis Dorokhov on 08/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import UIKit

class TestAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
}

let appDelegateClass: String
if let _ = NSClassFromString("XCTest") {
    appDelegateClass = NSStringFromClass(TestAppDelegate)
} else {
    appDelegateClass = NSStringFromClass(AppDelegate)
}

UIApplicationMain(Process.argc, Process.unsafeArgv, NSStringFromClass(UIApplication), appDelegateClass)