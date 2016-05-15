//
// Created by Denis Dorokhov on 12/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import Swinject

class ControllerAssembly: AssemblyType {
    func assemble(container: Container) {

        container.registerForStoryboard(CloudBootstrapController.self) {
            resolver, controller in
            controller.cloudBootstrapService = resolver.resolve(CloudBootstrapService.self)
        }

        container.registerForStoryboard(CloudBootstrapServerController.self) {
            resolver, controller in
            controller.errorNotifier = resolver.resolve(ErrorNotifier.self)
            controller.restUrlDao = resolver.resolve(RestUrlDao.self)
            controller.restService = resolver.resolve(RestService.self)
        }

        container.registerForStoryboard(CloudBootstrapLoginController.self) {
            resolver, controller in
            controller.errorNotifier = resolver.resolve(ErrorNotifier.self)
            controller.authService = resolver.resolve(AuthService.self)
        }

        container.registerForStoryboard(CloudArtistsController.self) {
            resolver, controller in
            controller.restService = resolver.resolve(RestService.self)
            controller.authService = resolver.resolve(AuthService.self)
            controller.errorNotifier = resolver.resolve(ErrorNotifier.self)
        }

        container.registerForStoryboard(CloudAlbumsController.self) {
            resolver, controller in
            controller.restService = resolver.resolve(RestService.self)
            controller.errorNotifier = resolver.resolve(ErrorNotifier.self)
            controller.libraryService = resolver.resolve(LibraryService.self)
        }
    }
}
