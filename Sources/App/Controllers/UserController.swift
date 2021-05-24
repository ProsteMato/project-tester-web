import Fluent
import Vapor

extension User {
    struct Public: Content {
        let id: UUID?
        let firstName: String
        let lastName: String
        let email: String
    }

    func convertToPublic() -> User.Public {
    // 2
        return User.Public(id: id, firstName: firstName, lastName: lastName, email: email)
    }
}

struct ProjectContext: Content {
    let id: UUID?
    let name: String
    let description: String
    let assignmentURL: String
    let testScriptURL: String
    let createdBy: User.Public
}


struct ProjectWebContext: Content {
    let title: String
    let projects: [Project]
}


struct UserController: RouteCollection {
    let sessionProtected: RoutesBuilder


    func boot(routes: RoutesBuilder) throws {
        sessionProtected.get("", use: index)
        sessionProtected.get("logout", use: handleLogout)
    }

    func index(req: Request) throws -> EventLoopFuture<View> {
        Project.query(on: req.db)
            .with(\.$createdBy).all().flatMap { projects in
                // let projectsData = projects.map { project in 
                //     ProjectContext(
                //         id: project.id,
                //         name: project.name,
                //         description: project.description,
                //         assignmentURL: project.assignmentURL,
                //         testScriptURL: project.testScriptURL,
                //         createdBy: project.createdBy.convertToPublic()
                //     )
                // }

                let projectsContext = ProjectWebContext(
                    title: "Projects",
                    projects: projects
                )
                return req.view.render("projects", projectsContext)

            }
        
        // Project.query(on: req.db)
        //     .join(User.self, on: \Project.$createdBy.$id == \User.$id)
        //     .all()
        //     .flatMapThrowing { projects in
        //     var projectsData: [(Project, User)]
        //     let projectsAlone = projects.isEmpty ? nil : projects

        //     for project in projectsAlone {
        //         let user = try project.joined(User.self)
        //         projectsData.append((project, user))
        //     }

        //     let context = ProjectContext(title: "Projects", projects: projectsData)
        //     return req.view.render("projects", context)
        // }
    }

    func handleLogout(req: Request) throws -> Response {
        req.auth.logout(User.self)
        req.session.destroy()
        return req.redirect(to: "/login")
    }
}