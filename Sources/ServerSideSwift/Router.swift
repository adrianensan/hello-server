import Dispatch
import Foundation
import COpenSSL

class Router {
    static var routingTable = [String: Server]()
    static var listeningPorts = [UInt16: ServerSocket]()
    
    static func addServer(host: String, port: UInt16, usingTLS: Bool, server: Server) {
        if Router.listeningPorts[port] == nil {
            routingTable[":\(port)"] = server
            DispatchQueue(label: "serverOnPort:\(port)").async {
                Router.listeningPorts[port] = ServerSocket(port: port, usingTLS: false)
                while let newClient = Router.listeningPorts[port]?.acceptConnection() {
                    DispatchQueue(label: "client-\(newClient)").async {
                        if let newClient = newClient as? ClientSocket,
                            let clientHello = newClient.peak() {
                            let requestedHost = getHost(clientHello: clientHello)
                            print(requestedHost)
                            if let server = routingTable["\(requestedHost):\(port)"] {
                                
                            } else if let server = routingTable[":\(port)"] {
                                
                            }
                        }
                    }
                }
            }
        }
        
        routingTable["\(host):\(port)"] = server
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
            pos += Int(clientHello[pos])
            pos += 1
        }
        
        if clientHello.count > pos + 2 { // CipherSuite
            pos += convertToInt(bytes: [UInt8](clientHello[pos..<(pos + 2)]))
            pos += 2
        }
        
        if clientHello.count > pos + 1 { // Compression
            pos += Int(clientHello[pos])
            pos += 1
        }
        
        if clientHello.count > pos + 2 { // Extensions
            let data = Data(bytes: clientHello[pos..<(pos + 2)])
            let value = convertToInt(bytes: [UInt8](clientHello[pos..<(pos + 2)]))
            pos += 2
        }
        
        while clientHello.count > pos + 8 { // Extensions
            let extensionType = convertToInt(bytes: [UInt8](clientHello[pos..<(pos + 2)]))
            print(clientHello[pos..<(pos + 2)])
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
