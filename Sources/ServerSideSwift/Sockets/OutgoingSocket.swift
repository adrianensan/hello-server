import Foundation
import CoreFoundation

class OutgoingSocket: Socket {
  
  #if os(Linux)
  static let socketStremType = Int32(SOCK_STREAM.rawValue)
  
  static func hostToNetworkByteOrder(_ port: UInt16) -> UInt16 {
    return CFSwapInt16(port)
  }
  #else
  static let socketStremType = SOCK_STREAM
  
  static func hostToNetworkByteOrder(_ port: UInt16) -> UInt16 {
    return Int(OSHostByteOrder()) == OSLittleEndian ? CFSwapInt16(port) : port
  }
  #endif
  
  init?(to host: String, port: UInt16) {
    let socketFD = socket(AF_INET, ServerSocket.socketStremType, 0)
    super.init(socketFD: socketFD)
    
    guard socketFileDescriptor >= 0 else { return nil }
    
    var result: UnsafeMutablePointer<addrinfo>?
    getaddrinfo(host, nil, nil, &result)
    
    var value = 1
    guard setsockopt(socketFileDescriptor,
                     SOL_SOCKET,
                     SO_REUSEADDR,
                     &value, socklen_t(MemoryLayout<Int32>.size)) != -1 else {
                      fatalError("setsockopt failed.")
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
  
}
