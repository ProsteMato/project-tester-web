import Fluent
import Vapor

final class SubmittedProject: Model, Content {

    static let schema = "submittedProjects"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "stdout")
    var stdout: String

    @Field(key: "stderr")
    var stderr: String

    @Field(key: "returnValue")
    var returnValue: String

    @Field(key: "submittedFileURL")
    var submittedFileURL: String

    @Parent(key: "createdBy")
    var createdBy: User

    @Parent(key: "project")
    var project: Project

    init() { }

    init(id: UUID? = nil, stdout: String, stderr: String, returnValue: String, submittedFileURL: String,
        createdBy: User, project: Project) throws {
        self.id = id
        self.stdout = stdout
        self.stderr = stderr
        self.returnValue = returnValue
        self.submittedFileURL = submittedFileURL
        self.$createdBy.id = try createdBy.requireID()
        self.$project.id = try project.requireID()
    }
}