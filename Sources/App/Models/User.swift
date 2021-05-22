import Fluent
import Vapor

final class User: Model, Content {

    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "surname")
    var surname: String

    @Field(key: "email")
    var email: String

    @Field(key: "login")
    var login: String

    @Children(for: \.$createdBy)
    var projects: [Project]

    @Children(for: \.$createdBy)
    var submittedProjects: [SubmittedProject]

    
    init() { }

    init(id: UUID? = nil, name: String, surname: String, 
         email: String, login: String) 
    {
        self.id = id
        self.name = name
        self.surname = surname
        self.email = email
        self.login = login
    }
    
}