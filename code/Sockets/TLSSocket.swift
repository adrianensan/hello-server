import Foundation

import HelloCore
import OpenSSL

class TLSSocket: TCPSocket {
  
  var sslSocket: OpaquePointer?
  
  public func initSSL(sslContext: OpaquePointer) {
    sslSocket = SSL_new(sslContext)
    SSL_set_fd(sslSocket, socketFileDescriptor)
    SSL_set_read_ahead(sslSocket, 1)
//    SSL_set_mode(sslSocket, SSL_MODE_ENABLE_PARTIAL_WRITE)
  }
  
  override func sendDataPass(data: [UInt8]) throws -> Int {
    
    guard let sslSocket = sslSocket else {
      throw SSLError.initFail
    }
    var data = data
    let bytesSent = SSL_write(sslSocket, &data, min(8192, Int32(data.count)))
    Log.verbose("Sending \(bytesSent) bytes to \(socketFileDescriptor)", context: "TLS Socket")
    guard bytesSent > 0 else {
      let error = SSL_get_error(sslSocket, bytesSent)
      switch error {
      case SSL_ERROR_WANT_WRITE: throw SocketError.cantWriteYet
      case SSL_ERROR_WANT_READ: throw SocketError.cantReadYet
      case SSL_ERROR_ZERO_RETURN: throw SocketError.closed
      default: throw SSLError.initFail
      }
    }
    return Int(bytesSent)
  }
  
  override func rawRecieveData() throws -> [UInt8] {
    guard let sslSocket = sslSocket else { throw SocketError.closed }
    var recieveBuffer: [UInt8] = [UInt8](repeating: 0, count: Socket.bufferSize)
    let bytesRead = SSL_read(sslSocket, &recieveBuffer, Int32(Socket.bufferSize))
    guard bytesRead > 0 else {
      switch SSL_get_error(sslSocket, bytesRead) {
      case SSL_ERROR_WANT_READ: throw SocketError.cantReadYet
      case SSL_ERROR_WANT_WRITE: throw SocketError.cantWriteYet
      case SSL_ERROR_ZERO_RETURN: throw SocketError.closed
      default: throw SSLError.initFail
      }
    }
    Log.verbose("Read \(bytesRead) bytes from \(socketFileDescriptor)", context: "SSL Socket")
    return [UInt8](recieveBuffer[..<Int(bytesRead)])
  }
}
