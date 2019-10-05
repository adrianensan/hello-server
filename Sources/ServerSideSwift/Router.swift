import Dispatch
import Foundation
import OpenSSL

class Router {

  static var routingTable = [String: Server]()
  static var listeningPorts = [UInt16: ServerSocket]()

  static func addServer(host: String, port: UInt16, usingTLS: Bool, server: Server) {
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
          
            if let server = routingTable["\(requestedHost):\(port)"] {
              server.handleConnection(socket: newClient)
            } else if let server = routingTable[":\(port)"] {
              server.handleConnection(socket: newClient)
            }
          }
        }
      }
    }
      
    routingTable["\(host):\(port)"] = server
    if server.connectionHandling == .acceptAll && routingTable[":\(port)"] == nil { routingTable[":\(port)"] = server }
    signal(SIGPIPE, SIG_IGN)
  }

  static func convertToInt(bytes: [UInt8]) -> Int {
    var result: Int = 0
    for i in 0..<bytes.count {
      result += Int(bytes[i]) << (8 * (bytes.count - i - 1))
    }
    return result
  }

  static func getHost(clientHello: [UInt8]) -> String {
    var pos = 0
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
      pos += 2 + convertToInt(bytes: [UInt8](clientHello[pos..<(pos + 2)]))
    }
    
    if clientHello.count > pos + 1 { // Compression
      pos += 1 + Int(clientHello[pos])
    }
    
    pos += 2 // Extensions
    
    while clientHello.count > pos + 8 { // Extensions
      let extensionType = convertToInt(bytes: [UInt8](clientHello[pos..<(pos + 2)]))
      pos += 2
      let extensionLength = convertToInt(bytes: [UInt8](clientHello[pos..<(pos + 2)]))
      pos += 2
      if extensionType == TLSEXT_TYPE_server_name {
        let listLength = convertToInt(bytes: [UInt8](clientHello[pos..<(pos + 2)]))
        pos += 2
        if clientHello.count >= pos + listLength && clientHello[pos] == 0 {
          pos += 1
          let serverNameLength = convertToInt(bytes: [UInt8](clientHello[pos..<(pos + 2)]))
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
