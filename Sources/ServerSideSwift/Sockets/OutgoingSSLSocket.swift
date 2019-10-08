import Foundation
import CoreFoundation
import OpenSSL

public class OutgoingSSLSocket: Socket {
  
  let host: String
  
  var sslSocket: UnsafeMutablePointer<SSL>?
  
  public init?(to host: String, port: UInt16 = Socket.defaultHTTPSPort) {
    self.host = host
    var result: UnsafeMutablePointer<addrinfo>?
    getaddrinfo(host, "\(port)", nil, &result)
    
    var addrInfo = result?.pointee
    while addrInfo != nil {
      if addrInfo?.ai_socktype == OutgoingSocket.socketStremType {
        break
      }
      addrInfo = addrInfo?.ai_next?.pointee
    }
    
    guard let addr = addrInfo else {
      return nil
    }
    
    let socketFD = socket(addr.ai_family, addr.ai_socktype, addr.ai_protocol)
    guard socketFD > 0 else { return nil }
    
    if connect(socketFD, addr.ai_addr, addr.ai_addrlen) < 0 {
      return nil
    }
    
    super.init(socketFD: socketFD)
    
    /*
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
     */
  }
  
  deinit {
    //close(socketFileDescriptor)
  }
  
  public func initSSLConnection(sslContext: UnsafeMutablePointer<SSL_CTX>) {
    sslSocket = SSL_new(sslContext);
    SSL_set_fd(sslSocket, socketFileDescriptor)
    //SSL_CTX_set_info_callback(sslContext, infoCallback)
    let ssl_err = SSL_connect(sslSocket)
    if ssl_err <= 0 {
      
      print("damn failed\(SSL_get_error(sslSocket, 0))")
      close(socketFileDescriptor)
      
    }
  }
  
  public func sendAndWait(_ request: Request) -> Response? {
    let requestBytes: [UInt8] = [UInt8](request.data)
    print(request)
    sendData(data: requestBytes)
    print("Now waiting")
    return getResponse()
  }
  
  func getResponse() -> Response? {
    var responseBuffer: [UInt8] = [UInt8](repeating: 0, count: Socket.bufferSize)
    var responseLength: Int = 0
    while true {
      let bytesRead = SSL_read(sslSocket, &responseBuffer[responseLength], Int32(Socket.bufferSize - responseLength))
      guard bytesRead > 0 else { return nil }
      responseLength += Int(bytesRead)
      if let response = Response.parse(data: responseBuffer[..<responseLength].filter{ $0 != 13 }) {
        return response
      }
    }
  }
  
  func sendData(data: [UInt8]) {
    var bytesToSend = data.count
    repeat {
      guard let sslSocket = sslSocket else { return }
      let bytesSent = SSL_write(sslSocket, data, Int32(bytesToSend))
      if bytesSent <= 0 { return }
      bytesToSend -= Int(bytesSent)
    } while bytesToSend > 0
  }
}
