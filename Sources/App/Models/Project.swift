import Fluent
import Vapor

extension Project {
   struct Create: Content {
       let name: String
       let description: String
       let assignmentURL: File
       let testScriptURL: File
   }
}
extension Project {
    struct SubmitProject: Content {
       let submittedProject: File
   }
}

final class Project: Model, Content {

    static let schema = "projects"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "description")
    var description: String

    @Field(key: "assignmentURL")
    var assignmentURL: String

    @Field(key: "testScriptURL")
    var testScriptURL: String

    @Parent(key: "user_id")
    var createdBy: User

    @Children(for: \.$project)
    var submittedProjects: [SubmittedProject]

    init() { }

    init(id: UUID? = nil, name: String, description: String,
        assignmentURL: String, testScriptURL: String, createdBy: User) throws {
        self.id = id
        self.name = name
        self.description = description
        self.assignmentURL = assignmentURL
        self.testScriptURL = testScriptURL
        self.$createdBy.id = try createdBy.requireID()
    }
}