import Foundation

public class Socket {
    
  public static let defaultHTTPPort: UInt16 = 80
  public static let defaultHTTPSPort: UInt16 = 443
  static let bufferSize = 100 * 1024
  
  let socketFileDescriptor: Int32
  
  init(socketFD: Int32) {
    socketFileDescriptor = socketFD
  }
  
  deinit {
    close(socketFileDescriptor)
  }
}
