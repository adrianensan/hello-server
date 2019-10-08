import Foundation
import CoreFoundation

public class Socket {
    
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
  
  public static let defaultHTTPPort: UInt16 = 80
  public static let defaultHTTPSPort: UInt16 = 80
  static let bufferSize = 100 * 1024
  
  let socketFileDescriptor: Int32
  
  init(socketFD: Int32) {
    socketFileDescriptor = socketFD
  }
  
  deinit {
    close(socketFileDescriptor)
  }
}
