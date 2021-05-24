import Fluent
import Vapor

extension User {
    struct Create: Content {
        var firstName: String
        var lastName: String
        var email: String
        var password: String
        var confirmPassword: String
    }
}

extension User.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("firstName", as: String.self, is: !.empty)
        validations.add("lastName", as: String.self, is: !.empty)
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
    }
}

struct RegisterUserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let register = routes.grouped("register")
        register.get(use: index)
        register.post(use: create)
    }

    func index(req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("registration", ["title": "Register"])
    }

    func create(req: Request) throws -> EventLoopFuture<Response> {
        try User.Create.validate(content: req)
        let create = try req.content.decode(User.Create.self)
        guard create.password == create.confirmPassword else {
            throw Abort(.badRequest, reason: "Password did not match")
        }

        let user = try User(
                    firstName: create.firstName,
                    lastName: create.lastName,
                    email: create.email,
                    passwordHash: Bcrypt.hash(create.password)
                )
        
        return user.create(on: req.db)
            .flatMapErrorThrowing {
                if let dbError = $0 as? DatabaseError, dbError.isConstraintFailure {
                    throw Abort(.badRequest, reason: "User with this email exists!")
                }
                throw $0
            }
            .map { req.redirect(to: "/login") }        
    }
}