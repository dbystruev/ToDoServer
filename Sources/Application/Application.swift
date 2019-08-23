import Dispatch
import Foundation
import Kitura
import LoggerAPI
import Configuration
import CloudEnvironment
import KituraContracts
import Health
import KituraOpenAPI
import KituraCORS
import SwiftKueryORM
import SwiftKueryPostgreSQL

public let projectPath = ConfigurationManager.BasePath.project.path
public let health = Health()

public class App {
    // MARK: - Stored Variables
//    private var todoStore = [ToDo]()
    private var nextId = 0
    private var workerQueue = DispatchQueue(label: "worker")
    
    // MARK: - Constants
    let router = Router()
    let cloudEnv = CloudEnv()

    // MARK: - Initialization
    public init() throws {
        // Run the metrics initializer
        initializeMetrics(router: router)
    }

    func postInit() throws {
        // Database setup
        Persistence.setUp()
        do {
            try ToDo.createTableSync()
        } catch let error {
            print(#line, #function, "WARNING: Table already exists. \(error.localizedDescription)")
        }
        
        // Endpoints
        initializeHealthRoutes(app: self)
        KituraOpenAPI.addEndpoints(to: router)

        // KituraCORS
        let options = Options(allowedOrigin: .all)
        let cors = CORS(options: options)
        router.all("/*", middleware: cors)
        router.delete("/", handler: deleteAllHandler)
        router.delete("/", handler: deleteOneHandler)
        router.get("/", handler: getAllHandler)
        router.get("/", handler: getOneHandler)
        router.patch("/", handler: updateHandler)
        router.post("/", handler: storeHandler)
    }

    // MARK: - DELETE Handlers
    func deleteAllHandler(completion: @escaping (RequestError?) -> Void) {
//        execute {
//            todoStore = []
//        }
//        completion(nil)
        ToDo.deleteAll(completion)
    }
    
    func deleteOneHandler(id: Int, completion: @escaping (RequestError?) -> Void) {
//        guard let index = todoStore.firstIndex(where: { $0.id == id }) else {
//            return completion(.notFound)
//        }
//        execute {
//            todoStore.remove(at: index)
//        }
//        completion(nil)
        ToDo.delete(id: id, completion)
    }

    // MARK: - GET Handlers
    func getAllHandler(completion: @escaping ([ToDo]?, RequestError?) -> Void) {
//        completion(todoStore, nil)
        ToDo.findAll(completion)
    }
    
    func getOneHandler(id: Int, completion: @escaping (ToDo?, RequestError?) -> Void) {
//        guard let todo = todoStore.first(where: { $0.id == id }) else {
//            return completion(nil, .notFound)
//        }
//        completion(todo, nil)
        ToDo.find(id: id, completion)
    }
    
    // MARK: - PATCH Handlers
    func updateHandler(id: Int, new: ToDo, completion: @escaping (ToDo?, RequestError?) -> Void) {
//        guard let index = todoStore.firstIndex(where: { $0.id == id }) else {
//            return completion(nil, .notFound)
//        }
//        var current = todoStore[index]
        
        ToDo.find(id: id) { current, error in
            guard error == nil else {
                return completion(nil, error)
            }
            
            guard var current = current else {
                return completion(nil, .notFound)
            }
            
            guard id == current.id else {
                return completion(nil, .internalServerError)
            }
            
            current.user = new.user ?? current.user
            current.order = new.order ?? current.order
            current.title = new.title ?? current.title
            current.completed = new.completed ?? current.completed
            
            current.update(id: id, completion)
        }
        
        
//        execute {
//            todoStore[index] = current
//        }
//        completion(current, nil)
    }

    // MARK: - POST Handlers
    func storeHandler(todo: ToDo, completion: @escaping (ToDo?, RequestError?) -> Void) {
        var todo = todo
        if todo.completed == nil {
            todo.completed = false
        }
        todo.id = nextId
        todo.url = "http://localhost:8080/\(nextId)"
        nextId += 1
//        execute {
//            todoStore.append(todo)
//        }
//        completion(todo, nil)
        todo.save(completion)
    }

    // MARK: - Running
    public func run() throws {
        try postInit()
        Kitura.addHTTPServer(onPort: cloudEnv.port, with: router)
        Kitura.run()
    }

    func execute(_ block: () -> Void) {
        workerQueue.sync {
            block()
        }
    }
}

