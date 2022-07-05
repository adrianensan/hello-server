import Foundation
import CoreFoundation
import OpenSSL

import HelloLog

enum SocketError: Error {
  case closed
  case nothingToRead
}

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

  static let bufferSize = 100 * 1024
  
  let socketFileDescriptor: Int32
  
  init(socketFD: Int32) {
    Log.verbose("Opened on \(socketFD)", context: "Socket")
    socketFileDescriptor = socketFD
    guard fcntl(socketFileDescriptor, F_SETFL, fcntl(socketFileDescriptor, F_GETFL, 0) | O_NONBLOCK) == 0 else {
      fatalError("failed to make socket non-blocking.")
    }
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
  
  func rawRecieveData() throws -> [UInt8] {
    var recieveBuffer: [UInt8] = [UInt8](repeating: 0, count: Socket.bufferSize)
    let bytesRead = recv(socketFileDescriptor, &recieveBuffer, Socket.bufferSize, Int32(MSG_DONTWAIT))
    guard bytesRead > 0 else {
      switch errno {
      case EAGAIN, EWOULDBLOCK: throw SocketError.nothingToRead
      default: throw SocketError.closed
      }
    }
    Log.verbose("Read \(bytesRead) bytes from \(socketFileDescriptor)", context: "Socket")
    return [UInt8](recieveBuffer[..<Int(bytesRead)])
  }
  
  func recieveDataBlock() async throws -> [UInt8] {
    while true {
      do {
        return try rawRecieveData()
      } catch SocketError.nothingToRead {
        try await SocketPool.main.waitForChange(on: self)
      }
    }
  }
}
