import Fluent

struct CreateProject: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("projects")
            .id()
            .field("name", .string, .required)
            .field("description", .string, .required)
            .field("assignmentURL", .string, .required)
            .field("testScriptURL", .string, .required)
            .field("user_id", .uuid, .required, .references("users", "id"))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("projects").delete()
    }
}