//
//  AppDelegate.swift
//  Pony
//
//  Created by Denis Dorokhov on 26/04/16.
//  Copyright © 2016 Denis Dorokhov. All rights reserved.
//

import UIKit
import Swinject
import XCGLogger

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var assembler: Assembler!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        let container = Container()
        assembler = try! Assembler(assemblies: [
                ServiceAssembly(),
                ControllerAssembly(),
        ], container: container)

        let logConfigurator = container.resolve(LogConfigurator.self)!

        logConfigurator.configure(XCGLogger.defaultInstance())

        SwinjectStoryboard.defaultContainer = container

        let storyboard = SwinjectStoryboard.create(name: "Main", bundle: nil)

        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        if let window = window {
            window.rootViewController = storyboard.instantiateInitialViewController()
            window.makeKeyAndVisible()
        }

        return true
    }

}

