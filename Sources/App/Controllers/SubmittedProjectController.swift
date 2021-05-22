import Fluent
import Vapor

struct SubmittedProjectController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let submittedProjects = routes.grouped("submittedProjects")
        submittedProjects.get(use: index)
        submittedProjects.post(use: create)
        submittedProjects.group(":submittedProjectID") { submittedProject in
            submittedProject.delete(use: delete)
        }
    }

    func index(req: Request) throws -> EventLoopFuture<[SubmittedProject]> {
        return SubmittedProject.query(on: req.db).all()
    }

    func create(req: Request) throws -> EventLoopFuture<SubmittedProject> {
        let submittedProject = try req.content.decode(SubmittedProject.self)
        return submittedProject.save(on: req.db).map { submittedProject }
    }

    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return SubmittedProject.find(req.parameters.get("submittedProjectID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
}