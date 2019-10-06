import Foundation

class Socket {
    
  static let bufferSize = 100 * 1024
  
  let socketFileDescriptor: Int32
  
  init(socketFD: Int32) {
    socketFileDescriptor = socketFD
  }
  
  deinit {
    close(socketFileDescriptor)
  }
}
