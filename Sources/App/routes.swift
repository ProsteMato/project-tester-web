import Fluent
import Vapor

func routes(_ app: Application) throws {

    let sessionEnabled = app.grouped(
        app.sessions.middleware,
        User.sessionAuthenticator()
    )

    let sessionProtected = app.grouped(
        app.sessions.middleware,
        User.sessionAuthenticator(),
        User.redirectMiddleware(path: "/login")
    )

    try app.register(collection: RegisterUserController())
    try app.register(collection: LoginUserController(sessionEnabled: sessionEnabled))
    try app.register(collection: UserController(sessionProtected: sessionProtected))
    try app.register(collection: ProjectController(sessionProtected: sessionProtected, publicDirectory: app.directory.publicDirectory))
}
