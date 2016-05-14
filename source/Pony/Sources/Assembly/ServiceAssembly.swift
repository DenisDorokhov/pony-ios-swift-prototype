//
// Created by Denis Dorokhov on 12/05/16.
// Copyright (c) 2016 Denis Dorokhov. All rights reserved.
//

import Foundation
import Swinject
import XCGLogger
import Haneke

class ServiceAssembly: AssemblyType {

    private static let DEBUG_ALAMOFIRE = false

    func assemble(container: Container) {

        container.register(LogConfigurator.self) {
            resolver in
#if DISABLE_LOGGING
            return LogConfigurator(level: .None)
#else
            return LogConfigurator(level: .Debug)
#endif
        }.inObjectScope(.Container)

        container.register(RestUrlDao.self) {
            resolver in
            return RestUrlDaoImpl()
        }.inObjectScope(.Container)

        container.register(TokenPairDao.self) {
            resolver in
            return TokenPairDaoImpl()
        }.inObjectScope(.Container)

        container.register(ErrorNotifier.self) {
            resolver in
            return ErrorNotifier()
        }.inObjectScope(.Container)

        container.register(AlamofireManager.self) {
            resolver in
            return AlamofireManager(debug: ServiceAssembly.DEBUG_ALAMOFIRE)
        }.inObjectScope(.Container)

        container.register(RestService.self) {
            resolver in
            let service = RestServiceImpl()
            service.alamofireManager = resolver.resolve(AlamofireManager.self)
            service.tokenPairDao = resolver.resolve(TokenPairDao.self)
            service.restUrlDao = resolver.resolve(RestUrlDao.self)
            return RestServiceCached(targetService: RestServiceQueuedProxy(targetService: service))
        }.inObjectScope(.Container)

        container.register(AuthService.self) {
            resolver in
            let service = AuthService()
            service.tokenPairDao = resolver.resolve(TokenPairDao.self)
            service.restService = resolver.resolve(RestService.self)
            return service
        }.inObjectScope(.Container)

        container.register(LibraryService.self) {
            resolver in
            let service = LibraryService()
            service.restService = resolver.resolve(RestService.self)
            return service
        }.inObjectScope(.Container)

        container.register(CloudBootstrapService.self) {
            resolver in
            let service = CloudBootstrapService()
            service.restUrlDao = resolver.resolve(RestUrlDao.self)
            service.authService = resolver.resolve(AuthService.self)
            return service
        }.inObjectScope(.Container)
    }
}
