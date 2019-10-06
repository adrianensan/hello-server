import Foundation
import CoreFoundation

public class OutgoingSocket: Socket {
  
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
  
  public init?(to host: String, port: UInt16 = Socket.defaultHTTPPort) {
    
    var result: UnsafeMutablePointer<addrinfo>?
    getaddrinfo(host, "\(port)", nil, &result)
    
    guard let addr = result?.pointee else {
      print("\nFailed to create\n")
      return nil
    }
    
    let socketFD = socket(addr.ai_family, addr.ai_socktype, addr.ai_protocol)
    super.init(socketFD: socketFD)
    
    guard socketFileDescriptor >= 0 else { return nil }
    
    //let size = socklen_t(addr?.ai_family == AF_INET ? MemoryLayout<sockaddr_in>.size : MemoryLayout<sockaddr_in6>.size)
    if connect(socketFileDescriptor, addr.ai_addr, addr.ai_addrlen) < 0 {
      print("\nConnection Failed \n")
      return nil
    }
    print("\nConnected!\n")
    
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
    close(socketFileDescriptor)
  }
  
  func getResponse() -> Response? {
    var responseBuffer: [UInt8] = [UInt8](repeating: 0, count: Socket.bufferSize)
    var responseLength: Int = 0
    let bytesRead = recv(socketFileDescriptor, &responseBuffer[responseLength], Socket.bufferSize - responseLength, 0)
    guard bytesRead > 0 else { return nil }
    responseLength += bytesRead
    return Response.parse(data: responseBuffer[..<responseLength].filter{$0 != 13})
  }
  
  func sendRequest(_ request: Request) {
    let requestBytes: [UInt8] = [UInt8](request.data)
    sendData(data: requestBytes)
  }
  
  func sendData(data: [UInt8]) {
    var bytesToSend = data.count
    repeat {
      let bytesSent = send(socketFileDescriptor, data, bytesToSend, ClientSocket.socketSendFlags)
      if bytesSent <= 0 { return }
      bytesToSend -= bytesSent
    } while bytesToSend > 0
  }
}
