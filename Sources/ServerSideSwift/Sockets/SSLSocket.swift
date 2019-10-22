import Foundation
import OpenSSL

class SSLSocket: Socket {
    
  /*
  func infoCallback(ssl: UnsafePointer<SSL>?, type: Int32, alertInfo: Int32) {
    if (type & SSL_CB_HANDSHAKE_START != 0) {
        
    }
  }*/
  
  var sslSocket: UnsafeMutablePointer<SSL>?
  
  public func initSSL(sslContext: UnsafeMutablePointer<SSL_CTX>) {
    sslSocket = SSL_new(sslContext);
    SSL_set_fd(sslSocket, socketFileDescriptor)
  }
  
  override func sendDataPass(data: [UInt8]) -> Int {
    guard let sslSocket = sslSocket else { return -1 }
    return Int(SSL_write(sslSocket, data, Int32(data.count)))
  }
  
  func peakDataBlock() -> [UInt8]? {
    var recieveBuffer: [UInt8] = [UInt8](repeating: 0, count: Socket.bufferSize)
    let bytesRead = recv(socketFileDescriptor, &recieveBuffer, Socket.bufferSize, Int32(MSG_PEEK))
    guard bytesRead > 0 else { return nil }
    return [UInt8](recieveBuffer[...bytesRead])
  }
  
  override func recieveDataBlock() -> [UInt8]? {
    guard let sslSocket = sslSocket else { return nil }
    var recieveBuffer: [UInt8] = [UInt8](repeating: 0, count: Socket.bufferSize)
    let bytesRead = SSL_read(sslSocket, &recieveBuffer, Int32(Socket.bufferSize))
    guard bytesRead > 0 else { return nil }
    return [UInt8](recieveBuffer[...Int(bytesRead)])
  }
}
