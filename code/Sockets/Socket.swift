import Foundation
import CoreFoundation

import HelloCore
import OpenSSL

enum SocketError: Error {
  case initFail
  case reuseFail
  case bindFail
  case listenFail
  case closed
  case errorLoop
  case cantReadYet
  case cantWriteYet
  case failedToMakeNonBlocking
}

public enum SocketType {
  case tcp
  case udp
  
  var systemValue: Int32 {
    switch self {
    #if os(Linux)
    case .tcp: return Int32(SOCK_STREAM.rawValue)
    case .udp: return Int32(SOCK_DGRAM.rawValue)
    #else
    case .tcp: return SOCK_STREAM
    case .udp: return SOCK_DGRAM
    #endif
    }
  }
}

public class Socket {
    
  #if os(Linux)
  static let socketSendFlags: Int32 = Int32(MSG_NOSIGNAL)
  static let socketUDPType = Int32(SOCK_DGRAM.rawValue)
  #else
  static let socketSendFlags: Int32 = 0
  static let socketUDPType = SOCK_DGRAM
  #endif
  
  public static let defaultHTTPPort: UInt16 = 80
  public static let defaultHTTPSPort: UInt16 = 443

  static let bufferSize = 64 * 1024
  
  let socketFileDescriptor: Int32
  
  init(socketFD: Int32) throws {
    Log.verbose("Opened on \(socketFD)", context: "Socket")
    socketFileDescriptor = socketFD
    guard fcntl(socketFileDescriptor, F_SETFL, fcntl(socketFileDescriptor, F_GETFL, 0) | O_NONBLOCK) == 0 else {
      throw SocketError.failedToMakeNonBlocking
    }
  }
  
  deinit {
    close(socketFileDescriptor)
  }
  
  func bindForInbound(to port: UInt16) throws {
    var value = 1
    guard setsockopt(socketFileDescriptor,
                     SOL_SOCKET,
                     SO_REUSEADDR,
                     &value, socklen_t(MemoryLayout<Int32>.size)) != -1 else {
      throw SocketError.reuseFail
    }
    
    #if !os(Linux)
    guard setsockopt(socketFileDescriptor,
                     SOL_SOCKET,
                     SO_NOSIGPIPE,
                     &value,
                     socklen_t(MemoryLayout<Int32>.size)) != -1 else {
      throw SocketError.initFail
    }
    #endif
    
    var addr = sockaddr_in()
    addr.sin_family = sa_family_t(AF_INET)
    addr.sin_port = hostToNetworkByteOrder(port)
    addr.sin_addr.s_addr = INADDR_ANY
    var saddr = sockaddr()
    memcpy(&saddr, &addr, MemoryLayout<sockaddr_in>.size)
    guard bind(socketFileDescriptor, &saddr, socklen_t(MemoryLayout<sockaddr_in>.size)) != -1 else {
      Log.error("Failed to bind socket on port \(port).", context: "Socket")
      throw SocketError.bindFail
    }
  }
}
