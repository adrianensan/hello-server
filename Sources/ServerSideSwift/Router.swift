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
          if !Security.shouldAllowConnection(from: newClient.ipAddress) { continue }
          DispatchQueue(label: "client-\(newClient)").async {
            var requestedHost = ""
            if let newClient = newClient as? ClientSSLSocket, let clientHello = newClient.peakRawData() {
              requestedHost = getHost(clientHello: clientHello)
            } else if let firstPacket = newClient.peakPacket() {
              requestedHost = firstPacket.host ?? ""
            }
            
            let server = routingTable["\(requestedHost):\(port)"] ?? routingTable[":\(port)"]
            server?.handleConnection(socket: newClient)
          }
        }
      }
    }
      
    routingTable["\(host):\(port)"] = routingTable["\(host):\(port)"] ?? server
    signal(SIGPIPE, SIG_IGN)
  }

  static func getHost(clientHello: [UInt8]) -> String {
    var pos: Int = 0
    pos += 1 // Type
    pos += 2 // Version
    pos += 2 // Length
    
    pos += 1 // Handshake Type
    pos += 3 // Length
    pos += 2 // Version
    
    pos += 32 // Random
    
    if clientHello.count > pos + 1 { // SessionID
      pos += 1 + Int(clientHello[pos])
    }
    
    if clientHello.count > pos + 2 { // CipherSuite
      pos += 2 + [UInt8](clientHello[pos..<(pos + 2)]).intValue
    }
    
    if clientHello.count > pos + 1 { // Compression
      pos += 1 + Int(clientHello[pos])
    }
    
    pos += 2 // Extensions
    
    while clientHello.count > pos + 8 { // Extensions
      let extensionType = [UInt8](clientHello[pos..<(pos + 2)]).intValue
      pos += 2
      let extensionLength = [UInt8](clientHello[pos..<(pos + 2)]).intValue
      pos += 2
      if extensionType == TLSEXT_TYPE_server_name {
        let listLength = [UInt8](clientHello[pos..<(pos + 2)]).intValue
        pos += 2
        if clientHello.count >= pos + listLength && clientHello[pos] == 0 {
          pos += 1
          let serverNameLength = [UInt8](clientHello[pos..<(pos + 2)]).intValue
          pos += 2
          if clientHello.count >= pos + serverNameLength {
            let serverNameData: Data = Data([UInt8](clientHello[pos..<(pos + serverNameLength)]))
            return String(data: serverNameData, encoding: .utf8) ?? ""
          } else {
            return ""
          }
        } else {
          return ""
        }
      } else {
        pos += extensionLength
      }
    }
    
    return ""
  }
}
