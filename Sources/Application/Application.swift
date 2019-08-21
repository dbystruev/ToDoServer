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

public let projectPath = ConfigurationManager.BasePath.project.path
public let health = Health()

public class App {
    private var todoStore = [ToDo]()
    private var nextId = 0
    private var workerQueue = DispatchQueue(label: "worker")

    let router = Router()
    let cloudEnv = CloudEnv()

    public init() throws {
        // Run the metrics initializer
        initializeMetrics(router: router)
    }

    func postInit() throws {
        // Endpoints
        initializeHealthRoutes(app: self)
        KituraOpenAPI.addEndpoints(to: router)

        // KituraCORS
        let options = Options(allowedOrigin: .all)
        let cors = CORS(options: options)
        router.all("/*", middleware: cors)
        router.delete("/", handler: deleteAllHandler)
        router.get("/", handler: getAllHandler)
        router.post("/", handler: storeHandler)
    }

    func deleteAllHandler(completion: (RequestError?) -> Void) {
        execute {
            todoStore = []
        }
        completion(nil)
    }

    func getAllHandler(completion: ([ToDo]?, RequestError?) -> Void) {
        completion(todoStore, nil)
    }

    func storeHandler(todo: ToDo, completion: (ToDo?, RequestError?) -> Void) {
        var todo = todo
        if todo.completed == nil {
            todo.completed = false
        }
        todo.id = nextId
        todo.url = "http://localhost:8081/\(nextId)"
        nextId += 1
        execute {
            todoStore.append(todo)
        }
        completion(todo, nil)
    }

    public func run() throws {
        try postInit()
        Kitura.addHTTPServer(onPort: 8081 /*cloudEnv.port*/, with: router)
        Kitura.run()
    }

    func execute(_ block: () -> Void) {
        workerQueue.sync {
            block()
        }
    }
}
