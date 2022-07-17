import Foundation

import HelloLog

public enum Connection {}

public extension Connection {
  static func connect(to ipAddress: IPAddress, port: UInt16 = 80) async throws -> ClientConnection {
    var addr = sockaddr_in()
    addr.sin_family = sa_family_t(AF_INET)
    addr.sin_addr.s_addr = inet_addr(ipAddress.string)
    addr.sin_port = ServerSocket.hostToNetworkByteOrder(port)
    
    let socketFD = socket(AF_INET, SocketType.udp.systemValue, 0)
    guard socketFD > 0 else {
      throw ConnectionError.failedToBind
    }
    let socket = try TCPSocket(socketFD: socketFD)
    
    var value = 1
    guard setsockopt(socketFD,
                     SOL_SOCKET,
                     SO_REUSEADDR,
                     &value, socklen_t(MemoryLayout<Int32>.size)) != -1 else {
      throw SocketError.reuseFail
    }
    
    var addrLocal = sockaddr_in()
    addrLocal.sin_family = sa_family_t(AF_INET)
    addrLocal.sin_port = ServerSocket.hostToNetworkByteOrder(port)
    addrLocal.sin_addr.s_addr = INADDR_ANY
    var saddr = sockaddr()
    memcpy(&saddr, &addrLocal, MemoryLayout<sockaddr_in>.size)
    guard bind(socketFD, &saddr, socklen_t(MemoryLayout<sockaddr_in>.size)) != -1 else {
      Log.error("Failed to bind socket on port \(port). errno: \(errno)", context: "Socket")
      throw SocketError.bindFail
    }
    
//    return try withUnsafePointer(to: addr) {
//      try $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
//        if Foundation.connect(socketFD, $0, socklen_t(MemoryLayout.size(ofValue: addr))) < 0 {
//          if errno == EINPROGRESS {
//            Log.info("connecting", context: "Connection")
//            Thread.sleep(forTimeInterval: 0.2)
//          } else {
//            Log.info("failed to \(ipAddress.string):\(port) with error \(errno)", context: "Connection")
//            throw ConnectionError.failedToConnect
//          }
//        }
        Log.info("open to \(ipAddress.string):\(port)", context: "Connection")
        return ClientConnection(socket: socket, clientAddress: ipAddress.string)
//      }
//    }
  }
}
