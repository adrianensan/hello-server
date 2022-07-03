import Foundation
import CoreFoundation
import System

class ServerSocket: Socket {
    
  static let acceptBacklog: Int32 = 20
  
  let usingTLS: Bool
  
  init(port: UInt16, usingTLS: Bool) {
    self.usingTLS = usingTLS
    let listeningSocket = socket(AF_INET, ServerSocket.socketStremType, 0)
    super.init(socketFD: listeningSocket)
    
    guard socketFileDescriptor >= 0 else { fatalError("Failed to initialize socket") }
    
    var value = 1
    guard setsockopt(socketFileDescriptor,
                     SOL_SOCKET,
                     SO_REUSEADDR,
                     &value, socklen_t(MemoryLayout<Int32>.size)) != -1 else {
      fatalError("setsockopt failed.")
    }
    
    guard fcntl(socketFileDescriptor, F_SETFL, fcntl(socketFileDescriptor, F_GETFL, 0) | O_NONBLOCK) == 0 else {
      fatalError("failed to make socket non-blocking.")
    }
    #if !os(Linux)
    guard setsockopt(socketFileDescriptor,
                     SOL_SOCKET,
                     SO_NOSIGPIPE,
                     &value,
                     socklen_t(MemoryLayout<Int32>.size)) != -1 else {
      fatalError("setsockopt failed.")
    }
    #endif
    
    var addr = sockaddr_in()
    addr.sin_family = sa_family_t(AF_INET);
    addr.sin_port = ServerSocket.hostToNetworkByteOrder(port);
    addr.sin_addr.s_addr = INADDR_ANY;
    var saddr = sockaddr()
    memcpy(&saddr, &addr, MemoryLayout<sockaddr_in>.size)
    guard bind(socketFileDescriptor, &saddr, socklen_t(MemoryLayout<sockaddr_in>.size)) != -1 else {
      fatalError("Failed to bind socket on port \(port).")
    }
    
    guard listen(socketFileDescriptor, ServerSocket.acceptBacklog) != -1 else {
      fatalError("Failed to listen on port \(port).")
    }
  }
  
  deinit {
    close(socketFileDescriptor)
  }
  
  func acceptConnection() async -> ClientConnection? {
    var clientAddrressStruct = sockaddr()
    var clientAddressLength = socklen_t(MemoryLayout<sockaddr>.size)
    var newConnectionFD: Int32 = -1
    while true {
      newConnectionFD = accept(socketFileDescriptor, &clientAddrressStruct, &clientAddressLength)
      guard newConnectionFD > 0 else {
        switch Errno(rawValue: errno) {
        case .resourceTemporarilyUnavailable, .wouldBlock:
          try? await Task.sleep(nanoseconds: 10_000_000)
          continue
        default:
          return nil
        }
      }
      break
    }
    
    var clientAddressBytes: [Int8] = [Int8](repeating: 0, count: Int(INET6_ADDRSTRLEN))
    switch clientAddrressStruct.sa_family {
    case sa_family_t(AF_INET):
      var ipv4 = sockaddr_in()
      memcpy(&ipv4, &clientAddrressStruct, MemoryLayout<sockaddr_in>.size)
      inet_ntop(AF_INET, &(ipv4.sin_addr), &clientAddressBytes, socklen_t(INET_ADDRSTRLEN));
    case sa_family_t(AF_INET6):
      clientAddressBytes = []
    default: break
    }
    
    clientAddressBytes = clientAddressBytes.filter {$0 != 0}
    let clientAddressBytesData = Data(bytes: clientAddressBytes, count: clientAddressBytes.count)
    guard let clientAddress = String(data: clientAddressBytesData, encoding: .utf8) else { return nil }
    
    if usingTLS {
      return SSLClientConnection(socket: SSLSocket(socketFD: newConnectionFD), clientAddress: clientAddress)
    } else {
      return ClientConnection(socket: Socket(socketFD: newConnectionFD), clientAddress: clientAddress)
    }
  }
}
