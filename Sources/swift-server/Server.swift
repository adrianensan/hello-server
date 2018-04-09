import Dispatch
import Foundation

class Server {

    var serverName: UInt16 = 8181
    var serverAddress: String?
    var httpPort: UInt16 = 80
    var httpsPort: UInt16 = 443
    var staticDocumentRoot: String = "./static"
    
    private var usingTLS = false
    private var listeningSocket: AcceptSocket?
    
    init() {
        
    }
    
    func useTLS(certificateFile: String, privateKeyFile: String) {
        SSLSocket.initSSLContext(certificateFile: certificateFile, privateKeyFile: privateKeyFile)
        usingTLS = true
    }
    
    func handleConnection(socket: Socket) {
        while let request = socket.acceptRequest() {
            let response = Response(clientSocket: socket)
            if request.method == .get {
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
        listeningSocket = AcceptSocket(port: usingTLS ? httpsPort : httpPort, usingTLS: usingTLS)
        while let newClient = listeningSocket?.acceptConnection() {
            DispatchQueue(label: "client-\(newClient)").async {
                self.handleConnection(socket: newClient)
            }
        }
    }
}
