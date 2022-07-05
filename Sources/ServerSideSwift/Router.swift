import Foundation

import OpenSSL
import HelloLog

actor Router {

  static var routingTable: [String: any Server] = [:]
  static var listeningPorts: [UInt16: ServerSocket] = [:]
  static var lastAccess: [String: String] = [:]

  static func add(server: some Server) {
    #if DEBUG
    let host: String = "localhost"
    let port: UInt16 = 8019 + UInt16(routingTable.count)
    let usingTLS: Bool = false
    #else
    let host: String = server.host
    let port: UInt16 = server.port
    let usingTLS: Bool = server is HTTPSServer
    #endif
    Security.startSecurityMonitor()
    if Router.listeningPorts[port] == nil {
      Router.listeningPorts[port] = ServerSocket(port: port, usingTLS: usingTLS)
      Log.info("Listening on port \(port)", context: "Init")
      Task {
        do {
          while let newClient = try await Router.listeningPorts[port]?.acceptConnection() {
            guard Security.shouldAllowConnection(from: newClient.clientAddress) else {
              Log.verbose("Rejected inbound from \(newClient.clientAddress)", context: "Connection")
              continue
            }
            Log.verbose("Accepted inbound from \(newClient.clientAddress)", context: "Connection")
            Task {
              let requestedHost: String
              do {
                requestedHost = try await newClient.getRequestedHost()
                lastAccess[newClient.clientAddress] = requestedHost
              } catch {
                if let lastHost = lastAccess[newClient.clientAddress] {
                  requestedHost = lastHost
                } else {
                  Log.warning("Failed to determine target host from \(newClient.clientAddress)", context: "Connection")
                  return
                }
              }
              guard let server = routingTable["\(requestedHost):\(port)"] ?? routingTable[":\(port)"] else {
                Log.warning("No server found for \(requestedHost):\(port)", context: "Connection")
                return
              }
              try await server.handleConnection(connection: newClient)
            }
          }
        } catch {
          Log.error("No longer accepting on port \(port)", context: "Router")
          fatalError("No longer accepting")
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
//    if let hostname = Host.current().localizedName {
//      Log.debug("\(hostname):\(port) - \(server.name)", context: "Init")
//      routingTable["\(hostname).local:\(port)"] = routingTable["\(hostname).local:\(port)"] ?? server
//    }
    #else
//    for additionalServer in server.additionalServers {
//      Router.add(server: additionalServer)
//    }
    #endif
    signal(SIGPIPE, SIG_IGN)
  }
}
