import Foundation
import CoreFoundation
import OpenSSL

public class Socket {
    
  #if os(Linux)
  static let socketSendFlags: Int32 = Int32(MSG_NOSIGNAL)
  static let socketStremType = Int32(SOCK_STREAM.rawValue)
  
  static func hostToNetworkByteOrder(_ port: UInt16) -> UInt16 {
    return CFSwapInt16(port)
  }
  #else
  static let socketSendFlags: Int32 = 0
  static let socketStremType = SOCK_STREAM
  
  static func hostToNetworkByteOrder(_ port: UInt16) -> UInt16 {
    return Int(OSHostByteOrder()) == OSLittleEndian ? CFSwapInt16(port) : port
  }
  #endif
  
  public static let defaultHTTPPort: UInt16 = 80
  public static let defaultHTTPSPort: UInt16 = 443
  public static let defaultDebugPort: UInt16 = 8018
  static let bufferSize = 100 * 1024
  
  let socketFileDescriptor: Int32
  
  init(socketFD: Int32) {
    socketFileDescriptor = socketFD
  }
  
  deinit {
    close(socketFileDescriptor)
  }
  
  func sendDataPass(data: [UInt8]) -> Int {
    return send(socketFileDescriptor, data, data.count, ClientSocket.socketSendFlags)
  }
  
  func sendData(data: [UInt8]) {
    var bytesToSend = data.count
    var bytesSent = 0
    repeat {
      bytesSent += sendDataPass(data: [UInt8](data[bytesSent...]))
      if bytesSent <= 0 { return }
      bytesToSend -= bytesSent
    } while bytesToSend > 0
  }
  
  func recieveDataBlock() -> [UInt8]? {
    var recieveBuffer: [UInt8] = [UInt8](repeating: 0, count: Socket.bufferSize)
    let bytesRead = recv(socketFileDescriptor, &recieveBuffer, Socket.bufferSize, 0)
    guard bytesRead > 0 else { return nil }
    return [UInt8](recieveBuffer[...bytesRead])
  }
  
  func recieveRequest() -> Request? {
    var recievedData: [UInt8] = []
    while true {
      guard let bytesRead = recieveDataBlock() else { return nil }
      recievedData += bytesRead
      if let request = Request.parse(data: recievedData.filter{$0 != 13}) { return request }
    }
  }
  
  func recieveResponse() -> Response? {
    var recievedData: [UInt8] = []
    while true {
      guard let bytesRead = recieveDataBlock() else { return nil }
      recievedData += bytesRead
      if let response = Response.parse(data: recievedData.filter{$0 != 13}) { return response }
    }
  }
}
