import Foundation

import OpenSSL
import HelloLog

class SSLSocket: Socket {
    
  /*
  func infoCallback(ssl: UnsafePointer<SSL>?, type: Int32, alertInfo: Int32) {
    if (type & SSL_CB_HANDSHAKE_START != 0) {
        
    }
  }*/
  
  var sslSocket: OpaquePointer?
  
  public func initSSL(sslContext: OpaquePointer) {
    sslSocket = SSL_new(sslContext)
    SSL_set_fd(sslSocket, socketFileDescriptor)
    SSL_set_read_ahead(sslSocket, 1)
    SSL_set_accept_state(sslSocket)
  }
  
  override func sendDataPass(data: [UInt8]) -> Int {
    Log.verbose("Sending \(data.count) bytes to \(socketFileDescriptor)", context: "SSL Socket")
    guard let sslSocket = sslSocket else { return -1 }
    return Int(SSL_write(sslSocket, data, Int32(data.count)))
  }
  
  func peakDataBlock() async throws -> [UInt8] {
    var recieveBuffer: [UInt8] = [UInt8](repeating: 0, count: Socket.bufferSize)
    let bytesRead = recv(socketFileDescriptor, &recieveBuffer, Socket.bufferSize, Int32(MSG_PEEK))
    guard bytesRead > 0 else {
      switch errno {
      case EAGAIN, EWOULDBLOCK: throw SocketError.nothingToRead
      default: throw SocketError.closed
      }
    }
    return [UInt8](recieveBuffer[..<bytesRead])
  }
  
  override func rawRecieveData() throws -> [UInt8] {
    guard let sslSocket = sslSocket else { throw SocketError.closed }
    var recieveBuffer: [UInt8] = [UInt8](repeating: 0, count: Socket.bufferSize)
    let bytesRead = SSL_read(sslSocket, &recieveBuffer, Int32(Socket.bufferSize))
    guard bytesRead > 0 else {
      switch SSL_get_error(sslSocket, bytesRead) {
      case SSL_ERROR_WANT_READ: throw SocketError.nothingToRead
      case SSL_ERROR_ZERO_RETURN: throw SocketError.closed
      default: throw SSLError.initFail
      }
    }
    Log.verbose("Read \(bytesRead) bytes from \(socketFileDescriptor)", context: "SSL Socket")
    return [UInt8](recieveBuffer[..<Int(bytesRead)])
  }
}
