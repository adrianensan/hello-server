import Foundation
import OpenSSL

class SSLClientConnection: ClientConnection {
  
  private let socket: SSLSocket
  private var peakedData: [UInt8]?
  
  override init(socket: Socket, clientAddress: String) {
    self.socket = socket as! SSLSocket
    super.init(socket: socket, clientAddress: clientAddress)
  }
  
  func initAccpetSSLHandshake(sslContext: UnsafeMutablePointer<SSL_CTX>) -> Bool {
    socket.initSSL(sslContext: sslContext)
    //SSL_CTX_set_info_callback(sslContext, infoCallback)
    return SSL_accept(socket.sslSocket) > 0
  }
  
  public func initConnectSSLHandshake(sslContext: UnsafeMutablePointer<SSL_CTX>) -> Bool {
    socket.initSSL(sslContext: sslContext)
    //SSL_CTX_set_info_callback(sslContext, infoCallback)
    return SSL_connect(socket.sslSocket) > 0
  }
  
  override func getRequestedHost() -> String? {
    if let peakedData = socket.peakDataBlock() {
      return SSLClientConnection.getHost(from: peakedData)
    }
    else { return nil }
  }
  
  static func getHost(from clientHello: [UInt8]) -> String {
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
