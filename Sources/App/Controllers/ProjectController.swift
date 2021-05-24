import Fluent
import Vapor
import Foundation


struct ProjectController: RouteCollection {
    let sessionProtected: RoutesBuilder
    let publicDirectory: String

    func boot(routes: RoutesBuilder) throws {
        let projects = sessionProtected.grouped("projects")
        projects.get(use: index)
        projects.post(use: create)
        projects.group(":projectID") { project in
            project.get(use: renderProject)
            project.get("assigment", use: getAssigment)
            project.get("testscript", use: getTestScript)
            project.post(use: submitProject)
        }
    }

    func index(req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("project_create", ["title": "Create project"])
    }

    func create(req: Request) throws -> EventLoopFuture<Response> {
        let project = try req.content.decode(Project.Create.self)
        let user: User = try req.auth.require(User.self)
        
        let assigmentPath = publicDirectory + "projects/assigments/\(UUID())-" + "" + project.assignmentURL.filename
        let testScriptPath = publicDirectory + "projects/scripts/\(UUID())-" + "" + project.testScriptURL.filename
        
        let newProject = try Project(
                            name: project.name,
                            description: project.description,
                            assignmentURL: assigmentPath,
                            testScriptURL: testScriptPath,
                            createdBy: user
                        )
        return req.fileio.writeFile(project.assignmentURL.data, at: assigmentPath)
            .flatMap { _ in
                req.fileio.writeFile(project.testScriptURL.data, at: testScriptPath)
                .flatMap { _ in
                    let redirect = req.redirect(to: "/")
                    return newProject.save(on: req.db).transform(to: redirect)
                }
            }
    }

    func renderProject(req: Request) throws -> EventLoopFuture<View> {
        return Project.find(req.parameters.get("projectID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { project in
                project.$createdBy.get(on: req.db).flatMap { user in
                    return req.view.render("project_detail", ["project": project]) 
                }
            }
    }

    func getAssigment(_ req: Request) -> EventLoopFuture<Response> {
        return Project.find(req.parameters.get("projectID"), on: req.db)
        .unwrap(or: Abort(.notFound))
        .flatMapThrowing { project in
            return req.fileio.streamFile(at: project.assignmentURL)
        }
    }

    func getTestScript(_ req: Request) -> EventLoopFuture<Response> {
        return Project.find(req.parameters.get("projectID"), on: req.db)
        .unwrap(or: Abort(.notFound))
        .flatMapThrowing { project in
            return req.fileio.streamFile(at: project.testScriptURL)
        }
    }

    func submitProject(req: Request) throws -> EventLoopFuture<EventLoopFuture<String>> {
        let file = try req.content.decode(Project.SubmitProject.self)
        let user = try req.auth.require(User.self)
        let submittedProjectPath = publicDirectory + "submittedProjects/\(UUID())-" + "" + file.submittedProject.filename
        
        
        return Project.find(req.parameters.get("projectID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing { project in 
                let newSubmittedProject = try SubmittedProject(
                    stdout: "",
                    stderr: "",
                    returnValue: "",
                    submittedFileURL: submittedProjectPath,
                    createdBy: user,
                    project: project
                )



                return req.fileio.writeFile(file.submittedProject.data, at: submittedProjectPath)
                    .flatMap { _ in
                        return SubmittedProject.query(on: req.db)
                            .filter(\SubmittedProject.$project.$id == project.id!)
                            .filter(\SubmittedProject.$createdBy.$id == user.id!)
                            .first()
                            .flatMap { submittedProject in 
                                if let _submittedProject = submittedProject {
                                    let fileManager = FileManager.default
                                    try! fileManager.removeItem(atPath: _submittedProject.submittedFileURL)
                                    _submittedProject.submittedFileURL = submittedProjectPath
                                    return _submittedProject.update(on: req.db)
                                    .map {
                                        return file.submittedProject.filename
                                    }
                                }
                                else {
                                    return newSubmittedProject.save(on: req.db)
                                    .map {
                                        return file.submittedProject.filename
                                    }
                                }
                            }
                    }
            }
    }
}