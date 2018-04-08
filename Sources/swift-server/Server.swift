import Dispatch
import Foundation

class Server {

    var serverName: UInt16 = 8181
    var serverAddress: String?
    var httpPort: UInt16 = 80
    var httpsPort: UInt16 = 443
    var staticDocumentRoot: String = "./static"
    
    var listeningSocket: Socket?
    
    init() {
        
    }
    
    func handleConnection(socket: Socket) {
        while let request = socket.acceptRequest() {
            let response = Response(clientSocket: socket)
            print(request)
            if request.method == .get {
                print(staticRoot + request.url + "index.html")
                if let file = try? String(contentsOf: URL(fileURLWithPath: staticDocumentRoot + request.url + "index.html"), encoding: .utf8) {
                    response.body = file
                    response.contentType = .html
                    response.complete()
                } else {
                    response.body = "Not Found"
                    response.status = .notFound
                    response.contentType = .html
                    response.complete()
                }
            }
        }
    }
    
    func start() {
        listeningSocket = Socket(port: httpPort)
        while let newClient = listeningSocket?.acceptConnection() {
            DispatchQueue(label: "client-\(newClient)").async {
                self.handleConnection(socket: newClient)
            }
        }
    }
}
