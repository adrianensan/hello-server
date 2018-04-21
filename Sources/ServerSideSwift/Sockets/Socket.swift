import Foundation

class Socket {
    
    static let bufferSize = 100 * 1024
    
    var socketFileDescriptor: Int32
    
    init(socketFD: Int32) {
        socketFileDescriptor = socketFD;
    }
    
    deinit {
        close(socketFileDescriptor)
    }
}
