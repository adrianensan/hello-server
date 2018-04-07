import Dispatch
import Foundation

class Server {
    
    var port: UInt16 = 8181
    var staticRoot: String = "./static"
    
    var listeningSocket: Socket?
    
    init() {
        
    }
    
    func handleConnection(socket: Socket) {
        while let request = socket.acceptRequest() {
            socket.sendResponse(Response())
        }
    }
    
    func start() {
        listeningSocket = Socket(port: port)
        while let newClient = listeningSocket?.acceptConnection() {
            print("3")
            let clientQueue = DispatchQueue(label: "client-\(newClient)")
            clientQueue.async {
                self.handleConnection(socket: newClient)
                print("FinishedConnection")
            }
            print("5")
        }
        print("Exiting")
    }
}
