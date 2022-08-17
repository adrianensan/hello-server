import Foundation

import HelloCore

public extension Connection {
  static func connect(to host: String, port: UInt16 = 80) async throws -> ClientConnection {
    var result: UnsafeMutablePointer<addrinfo>?
    getaddrinfo(host, "\(port)", nil, &result)
    
    var addrInfo = result?.pointee
    while addrInfo != nil {
      Log.debug("Loop 5", context: "Loop")
      if addrInfo?.ai_socktype == SocketType.tcp.systemValue {
        break
      }
      addrInfo = addrInfo?.ai_next?.pointee
    }
    
    guard let addr = addrInfo else {
      throw ConnectionError.failedToResolveHost
    }
    
    let socketFD = socket(addr.ai_family, addr.ai_socktype, addr.ai_protocol)
    guard socketFD > 0 else {
      throw ConnectionError.failedToBind
    }
    
    if Foundation.connect(socketFD, addr.ai_addr, addr.ai_addrlen) < 0 {
      throw ConnectionError.failedToConnect
    }
    return try ClientConnection(socket: TCPSocket(socketFD: socketFD), clientAddress: .init(ipAddress: .localhost, port: 80))
  }
}
