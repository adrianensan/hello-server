import Dispatch
import Foundation

class Router {
    static var routingTable = [UInt16: [Server]]()
    static var listeningPorts = [UInt16: ServerSocket]()
    
    static func addServer(host: String, port: UInt16, usingTLS: Bool, server: Server) {
        if Router.listeningPorts[port] == nil {
            DispatchQueue(label: "serverOnPort:\(port)").async {
                Router.listeningPorts[port] = ServerSocket(port: port, usingTLS: false)
                while let newClient = Router.listeningPorts[port]?.acceptConnection() {
                    DispatchQueue(label: "client-\(newClient)").async {
                        if let request = newClient.acceptRawData() {
                            print(request)
                        }
                    }
                }
            }
        }
    }
}
