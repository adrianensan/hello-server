import Dispatch
import Foundation
import OpenSSL

class Router {

  static var routingTable: [String: Server] = [:]
  static var listeningPorts: [UInt16: ServerSocket] = [:]

  static func add(server: Server) {
    let host: String = server.host
    let port: UInt16 = server.port
    let usingTLS: Bool = server is SSLServer
    Security.startSecurityMonitor()
    if Router.listeningPorts[port] == nil {
      Router.listeningPorts[port] = ServerSocket(port: port, usingTLS: usingTLS)
      DispatchQueue(label: "listeningSocket-\(port)").async {
        while let newClient = Router.listeningPorts[port]?.acceptConnection() {
          if !Security.shouldAllowConnection(from: newClient.clientAddress) { continue }
          DispatchQueue(label: "client-\(newClient)").async {
            let server = routingTable["\(newClient.getRequestedHost() ?? ""):\(port)"] ?? routingTable[":\(port)"]
            server?.handleConnection(connection: newClient)
          }
        }
      }
    }
      
    routingTable["\(host):\(port)"] = routingTable["\(host):\(port)"] ?? server
    signal(SIGPIPE, SIG_IGN)
  }
}
