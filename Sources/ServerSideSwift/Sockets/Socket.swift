import Foundation
import CoreFoundation
import OpenSSL
import System

import HelloLog

enum SocketError: Error {
  case closed
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
  
  func rawRecieveData() throws -> [UInt8] {
    var recieveBuffer: [UInt8] = [UInt8](repeating: 0, count: Socket.bufferSize)
    let bytesRead = recv(socketFileDescriptor, &recieveBuffer, Socket.bufferSize, MSG_DONTWAIT)
    guard bytesRead > 0 else {
      throw Errno(rawValue: errno)
    }
    Log.verbose("Read \(bytesRead) bytes from \(socketFileDescriptor)", context: "Socket")
    return [UInt8](recieveBuffer[..<Int(bytesRead)])
  }
  
  func recieveDataBlock() async throws -> [UInt8] {
    while true {
      do {
        return try rawRecieveData()
      } catch let error as Errno where error == .resourceTemporarilyUnavailable
                || error == .wouldBlock {
        switch await SocketPool.main.waitForChange(on: self) {
        case .idle: continue
        case .closed:
          Log.verbose("Closed \(socketFileDescriptor)", context: "Socket")
          throw SocketError.closed
        case .readyToRead: continue
        }
      }
    }
  }
}
