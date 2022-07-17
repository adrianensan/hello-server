import Foundation

import OpenSSL
import HelloLog

enum RouterError: Error {
  case invalidSerevrType
}

actor Router {

  static var udpServers: [UInt16: [any UDPServer]] = [:]
  static var tcpRoutingTable: [String: any TCPServer] = [:]
  static var listeningTCPPorts: [UInt16: ServerSocket] = [:]
  static var listeningUDPPorts: [UInt16: UDPSocket] = [:]
  static var lastAccess: [String: String] = [:]
  
  private static func listenForTCPConnection(on port: UInt16, usingTLS: Bool) throws {
    guard listeningTCPPorts[port] == nil else { return }
    listeningTCPPorts[port] = try ServerSocket(port: port, usingTLS: usingTLS)
    Log.info("Listening on port \(port)", context: "Init")
    Task {
      do {
        while let newClient = try await listeningTCPPorts[port]?.acceptConnection() {
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
                Log.warning("Failed to determine host from \(newClient.clientAddress)", context: "Connection")
                return
              }
            }
            guard let server = tcpRoutingTable["\(requestedHost):\(port)"] ?? tcpRoutingTable[":\(port)"] else {
              Log.warning("No server found for \(requestedHost):\(port)", context: "Connection")
              return
            }
            Log.verbose("from \(newClient.clientAddress) handled by \(requestedHost):\(port)", context: "Connection")
            if let sslServer = server as? SSLServer,
               let newClient = newClient as? SSLClientConnection {
              try await sslServer.handleConnection(sslConnection: newClient)
            } else {
              try await server.handleConnection(connection: newClient)
            }
          }
        }
      } catch {
        Log.error("No longer accepting on port \(port)", context: "Router")
        fatalError("No longer accepting")
      }
    }
  }
  
  private static func listenForUDPPackets(on port: UInt16) throws {
    guard listeningUDPPorts[port] == nil else { return }
    listeningUDPPorts[port] = try UDPServerSocket(port: port)
    Log.info("Listening on port \(port)", context: "Init")
    Task {
      do {
        while let packet = try await listeningUDPPorts[port]?.recievePacket() {
          guard Security.shouldAllowConnection(from: packet.originIPAddress.string) else {
            Log.verbose("Accepted UDP from \(packet.originIPAddress.string)", context: "Connection")
            continue
          }
          Log.verbose("Accepted UDP packet from \(packet.originIPAddress.string)", context: "Connection")
          guard let servers = udpServers[port] else { continue }
          Task {
            for server in servers {
              try await server.handle(data: packet.bytes, from: packet.originIPAddress)
            }
          }
        }
      } catch {
        Log.error("No longer accepting on port \(port). \(error)", context: "Router")
        fatalError("No longer accepting")
      }
    }
  }

  static func remove(server: some Server) async throws {
    let host: String = await server.host
    let port: UInt16 = await server.port
    let socketType: SocketType = await server.type
    
    switch socketType {
    case .tcp:
      tcpRoutingTable["\(host):\(port):"] = nil
      listeningTCPPorts[port] = nil
    case .udp:
      udpServers[port] = nil
      listeningUDPPorts[port] = nil
    }
  }
  
  static func add(server: some Server) async throws {
//    #if DEBUG
//    let host: String = "localhost"
//    let port: UInt16 = 8019 + UInt16(routingTable.count)
//    let usingTLS: Bool = false
//    #else
    let host: String = await server.host
    let port: UInt16 = await server.port
    let socketType: SocketType = await server.type
    let usingTLS: Bool = server is HTTPSServer
//    #endif
    Security.startSecurityMonitor()
    switch socketType {
    case .tcp:
      guard let tcpServer = server as? TCPServer else {
        throw RouterError.invalidSerevrType
      }
      try listenForTCPConnection(on: port, usingTLS: usingTLS)
      if tcpRoutingTable["\(host):\(port):"] == nil {
        Log.info("\(host):\(port):TCP - \(await server.name)", context: "Init")
        tcpRoutingTable["\(host):\(port)"] = tcpServer
      } else {
        Log.warning("Duplicate server for \(host):\(port), skipping", context: "Init")
      }
    case .udp:
      guard let udpServer = server as? UDPServer else {
        throw RouterError.invalidSerevrType
      }
      try listenForUDPPackets(on: port)
      if let socket = listeningUDPPorts[port] {
        await udpServer.socketUpdated(to: socket)
      }
      if udpServers[port] == nil {
        Log.info("\(host):\(port):UDP - \(await server.name)", context: "Init")
        udpServers[port] = (udpServers[port] ?? []) + [udpServer]
      } else {
        Log.warning("Duplicate server for \(host):\(port), skipping", context: "Init")
      }
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
