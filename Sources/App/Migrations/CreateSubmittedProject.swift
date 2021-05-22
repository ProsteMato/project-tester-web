import Fluent

struct CreateSubmittedProject: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("submittedProjects")
            .id()
            .field("stdout", .string, .required)
            .field("stderr", .string, .required)
            .field("returnValue", .string, .required)
            .field("submittedFileURL", .string, .required)
            .field("createdBy", .uuid, .required, .references("users", "id"))
            .field("project", .uuid, .required, .references("projects", "id"))
            .unique(on: "createdBy", "project")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("submittedProjects").delete()
    }
}