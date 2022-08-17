import Foundation

import HelloCore
import OpenSSL

enum SSLError: Error {
  case initFail
  case certFail
  case privateKeyFail
}

public class SSLClientConnection: ClientConnection {
  
  private let socket: TLSSocket
  
  init(socket: TLSSocket, clientAddress: NetworkAddress) {
    self.socket = socket
    super.init(socket: socket, clientAddress: clientAddress)
  }
  
  func initAccpetSSLHandshake(sslContext: OpaquePointer) async throws -> Void {
    socket.initSSL(sslContext: sslContext)
    
    var errorLoopCounter = 0
    while true {
      Log.debug("Loop 6", context: "Loop")
      let result = SSL_accept(socket.sslSocket)
      switch result {
      case 1: return
      case 0: throw SSLError.initFail
      default:
        switch SSL_get_error(socket.sslSocket, result) {
        case SSL_ERROR_WANT_READ: try await SocketPool.main.waitUntilReadable(socket)
        case SSL_ERROR_WANT_WRITE: try await SocketPool.main.waitUntilWriteable(socket)
        case SSL_ERROR_ZERO_RETURN: throw SocketError.closed
        default: throw SSLError.initFail
        }
      }
      guard errorLoopCounter < 3 else { throw SocketError.errorLoop }
      errorLoopCounter += 1
    }
  }
  
  public func initConnectSSLHandshake(sslContext: OpaquePointer) -> Bool {
    socket.initSSL(sslContext: sslContext)
    return SSL_connect(socket.sslSocket) > 0
  }
  
  override func getRequestedHost() async throws -> String {
    SSLClientConnection.getHost(from: try await socket.peakDataBlock())
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
            let host = String(data: serverNameData, encoding: .utf8) ?? ""
            return host.components(separatedBy: ":")[0]
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
