import Fluent
import Vapor

final class User: Model, Content {

    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "first_name")
    var firstName: String

    @Field(key: "last_name")
    var lastName: String

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String

    @Children(for: \.$createdBy)
    var projects: [Project]

    @Children(for: \.$createdBy)
    var submittedProjects: [SubmittedProject]

    
    init() { }

    init(id: UUID? = nil, firstName: String, lastName: String, 
         email: String, passwordHash: String) 
    {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.passwordHash = passwordHash
    }
}

extension User: ModelCredentialsAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$passwordHash

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}

extension User: ModelSessionAuthenticatable { }