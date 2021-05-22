import Fluent
import Vapor

struct ProjectController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let projects = routes.grouped("projects")
        projects.get(use: index)
        projects.post(use: create)
        projects.group(":projectID") { project in
            project.delete(use: delete)
        }
    }

    func index(req: Request) throws -> EventLoopFuture<[Project]> {
        return Project.query(on: req.db).all()
    }

    func create(req: Request) throws -> EventLoopFuture<Project> {
        let project = try req.content.decode(Project.self)
        return project.save(on: req.db).map { project }
    }

    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return Project.find(req.parameters.get("projectID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
}