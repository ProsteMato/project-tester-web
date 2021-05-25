import Fluent
import Vapor
import Foundation


struct TestOutput: Codable {
    let stdout: String
    let stderr: String
    let resultType: String
}


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
            project.webSocket("test", onUpgrade: handleSocket)
        }
    }

    func handleSocket(req: Request, ws: WebSocket) {
        guard let projectID = req.parameters.get("projectID") else  {
            ws.send("[server] - Bad projectID")
            return
        }
        let projectUUID: UUID? = UUID(projectID)
        let userID: User = try! req.auth.require(User.self)

        let _ = SubmittedProject.query(on: req.db)
            .filter(\SubmittedProject.$createdBy.$id == userID.id!)
            .filter(\SubmittedProject.$project.$id == projectUUID!)
            .first()
            .map { submittedProject in 
                if let _submittedProject = submittedProject {
                    let _ = _submittedProject.$project.get(on: req.db)
                    .map{ project in 
                        ws.send("[server] - Connection accepted")
                        ws.send("[server] - Establishing test")
                        let task = Process()
                        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                        task.arguments = ["bash", "Public/projects/scripts/\(project.testScriptURL)", "Public/submittedProjects/\(_submittedProject.submittedFileURL)"]

                        let pipe = Pipe()
                        let error = Pipe()
                        task.standardOutput = pipe
                        task.standardError = error
                        do {
                            try task.run()
                        } catch {
                            ws.send("[server] - Start of testing failed!")
                            let _ = ws.close()
                            return
                        }
                        
                        ws.send("[server] - Testing...")

                        let data = pipe.fileHandleForReading.readDataToEndOfFile()
                        let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
                        let output = String(data: data, encoding: String.Encoding.utf8)
                        let error_output = String(data: errorData, encoding: String.Encoding.utf8)
                        
                        task.waitUntilExit()
                        
                        ws.send("[server] - Testing ended. Creating results")

                        guard let _output = output, let _error = error_output else {
                            ws.send("[server] - Server error")
                            let _ = ws.close()
                            return
                        }
                        let results = TestOutput(
                            stdout: _output,
                            stderr: _error,
                            resultType: String(task.terminationStatus)
                        )
                        do {
                            let encoded_data = try JSONEncoder().encode(results)
                            ws.send("[server] - Sending results...")
                            ws.send(String(data: encoded_data, encoding: .utf8)!)
                        } catch {
                            ws.send("[server] - Server error")
                            let _ =  ws.close()
                        }

                        _submittedProject.stdout = _output
                        _submittedProject.stderr = _error
                        _submittedProject.returnValue = String(task.terminationStatus)
                        let _ = _submittedProject.update(on: req.db)
                        let _ = ws.close()
                    }
                } else {
                    ws.send("[server] - You did not submit project")
                    return
                }
            }
    }

    func index(req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("project_create", ["title": "Create project"])
    }

    func create(req: Request) throws -> EventLoopFuture<Response> {
        let project = try req.content.decode(Project.Create.self)
        let user: User = try req.auth.require(User.self)
        let scriptFilename = "\(UUID())-" + "" + project.testScriptURL.filename
        let assigmentFileName = "\(UUID())-" + "" + project.assignmentURL.filename
        let assigmentPath = publicDirectory + "projects/assigments/" + assigmentFileName
        let testScriptPath = publicDirectory + "projects/scripts/" + scriptFilename
        
        let newProject = try Project(
                            name: project.name,
                            description: project.description,
                            assignmentURL: assigmentFileName,
                            testScriptURL: scriptFilename,
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
        let assigmentPath = publicDirectory + "projects/assigments/"
        return Project.find(req.parameters.get("projectID"), on: req.db)
        .unwrap(or: Abort(.notFound))
        .flatMapThrowing { project in
            return req.fileio.streamFile(at: assigmentPath + project.assignmentURL)
        }
    }

    func getTestScript(_ req: Request) -> EventLoopFuture<Response> {
        let testScriptPath = publicDirectory + "projects/scripts/"
        return Project.find(req.parameters.get("projectID"), on: req.db)
        .unwrap(or: Abort(.notFound))
        .flatMapThrowing { project in
            return req.fileio.streamFile(at: testScriptPath + project.testScriptURL)
        }
    }

    func submitProject(req: Request) throws -> EventLoopFuture<EventLoopFuture<Response>> {
        let file = try req.content.decode(Project.SubmitProject.self)
        let user = try req.auth.require(User.self)
        let filename = "\(UUID())-" + file.submittedProject.filename
        let basePath = publicDirectory + "submittedProjects/"
        let submittedProjectPath = basePath + filename
        
        
        return Project.find(req.parameters.get("projectID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing { project in 
                let newSubmittedProject = try SubmittedProject(
                    stdout: "",
                    stderr: "",
                    returnValue: "",
                    submittedFileURL: filename,
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
                                    try! fileManager.removeItem(atPath: basePath + _submittedProject.submittedFileURL)
                                    _submittedProject.submittedFileURL = filename
                                    return _submittedProject.update(on: req.db)
                                    .map {
                                        return req.redirect(to: "/projects/\(project.id!)")
                                    }
                                }
                                else {
                                    return newSubmittedProject.save(on: req.db)
                                    .map {
                                        return req.redirect(to: "/projects/\(project.id!)")
                                    }
                                }
                            }
                    }
            }
    }
}