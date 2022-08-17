import Foundation
import CoreFoundation

import HelloCore

class ServerSocket: Socket {
    
  static let acceptBacklog: Int32 = 20
  
  let usingTLS: Bool
  
  init(port: UInt16, usingTLS: Bool) throws {
    self.usingTLS = usingTLS
    let listeningSocket = socket(AF_INET, SocketType.tcp.systemValue, 0)
    
    guard listeningSocket >= 0 else {
      throw SocketError.initFail
    }
    
    try super.init(socketFD: listeningSocket)
    
    try bindForInbound(to: port)
    
    guard listen(socketFileDescriptor, ServerSocket.acceptBacklog) != -1 else {
      Log.error("Failed to listen on port \(port).", context: "Socket")
      throw SocketError.listenFail
    }
  }
  
  deinit {
    close(socketFileDescriptor)
  }
  
  func acceptConnection() async throws -> ClientConnection {
    var clientAddrressStruct = sockaddr()
    var clientAddressLength = socklen_t(MemoryLayout<sockaddr>.size)
    var newConnectionFD: Int32 = -1
    while true {
      Log.verbose("accept attempt", context: "Router")
      clientAddrressStruct = sockaddr()
      clientAddressLength = socklen_t(MemoryLayout<sockaddr>.size)
      newConnectionFD = accept(socketFileDescriptor, &clientAddrressStruct, &clientAddressLength)
      guard newConnectionFD > 0 else {
        switch errno {
        case EAGAIN, EWOULDBLOCK:
          try await SocketPool.main.waitUntilReadable(self)
          Log.verbose("Ready to accept", context: "Router")
          continue
        default:
          throw SocketError.closed
        }
      }
      break
    }
    
    let clientAddress = try NetworkAddress(from: clientAddrressStruct)
    
    if usingTLS {
      return try SSLClientConnection(socket: TLSSocket(socketFD: newConnectionFD), clientAddress: clientAddress)
    } else {
      return try ClientConnection(socket: TCPSocket(socketFD: newConnectionFD), clientAddress: clientAddress)
    }
  }
}
