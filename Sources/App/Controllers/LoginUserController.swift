import Fluent
import Vapor


struct LoginUserController: RouteCollection {
    let sessionEnabled: RoutesBuilder


    func boot(routes: RoutesBuilder) throws {
        let credentialsProtectedRoute = sessionEnabled.grouped(User.credentialsAuthenticator())
        credentialsProtectedRoute.post("login", use: loginPostHandler)
        sessionEnabled.get("login", use: index)
    }

    func index(req: Request) -> EventLoopFuture<View> {
        return req.view.render("login", ["title": "Login"])
    }

    func loginPostHandler(req: Request) throws -> EventLoopFuture<Response> {
        if req.auth.has(User.self) {
            try req.session.authenticate(req.auth.require(User.self))
            return req.eventLoop.future(req.redirect(to: "/"))
        } else {
            return req.eventLoop.future(req.redirect(to: "/login"))
        }
    }
}