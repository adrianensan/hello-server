import Foundation

import OpenSSL
import HelloLog

actor Router {

  static var routingTable: [String: any Server] = [:]
  static var listeningPorts: [UInt16: ServerSocket] = [:]

  static func add(server: some Server) {
    #if DEBUG
    let host: String = "localhost"
    let port: UInt16 = 8019 + UInt16(routingTable.count)
    #else
    let host: String = server.host
    let port: UInt16 = server.port
    #endif
    let usingTLS: Bool = server is HTTPSServer
    Security.startSecurityMonitor()
    if Router.listeningPorts[port] == nil {
      Router.listeningPorts[port] = ServerSocket(port: port, usingTLS: usingTLS)
      Log.info("Listening on port \(port)", context: "Init")
      Task {
        while let newClient = await Router.listeningPorts[port]?.acceptConnection() {
          Log.verbose("New inbound from \(newClient.clientAddress)", context: "Connection")
          if !Security.shouldAllowConnection(from: newClient.clientAddress) { continue }
          Task {
            let requestedHost = try await newClient.getRequestedHost()
            guard let server = routingTable["\(requestedHost):\(port)"] ?? routingTable[":\(port)"] else {
              Log.warning("No server found for \(requestedHost):\(port)", context: "Connection")
              return
            }
            try await server.handleConnection(connection: newClient)
          }
        }
      }
    }
      
    if routingTable["\(host):\(port)"] == nil {
      Log.info("\(host):\(port) - \(server.name)", context: "Init")
      routingTable["\(host):\(port)"] = server
    } else {
      Log.warning("Duplicate server for \(host):\(port), skipping", context: "Init")
    }
    #if DEBUG
    if let hostname = Host.current().localizedName {
      Log.debug("\(hostname):\(port) - \(server.name)", context: "Init")
      routingTable["\(hostname).local:\(port)"] = routingTable["\(hostname).local:\(port)"] ?? server
    }
    #else
    for additionalServer in server.additionalServers {
      Router.add(server: additionalServer)
    }
    #endif
    signal(SIGPIPE, SIG_IGN)
  }
}
