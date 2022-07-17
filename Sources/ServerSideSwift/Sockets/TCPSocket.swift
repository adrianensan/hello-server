import Foundation
import CoreFoundation
import OpenSSL

import HelloLog

public class TCPSocket: Socket {
  
  func sendDataPass(data: [UInt8]) throws -> Int {
    Log.verbose("Sending \(data.count) bytes to \(socketFileDescriptor)", context: "Socket")
    return send(socketFileDescriptor, data, data.count, Socket.socketSendFlags)
  }
  
  func sendData(data: [UInt8]) async throws {
    var bytesToSend = data.count
    var bytesSent = 0
    while bytesToSend > 0 {
      bytesSent += try sendDataPass(data: [UInt8](data[bytesSent...]))
      if bytesSent <= 0 {
        throw SocketError.closed
      }
      bytesToSend -= bytesSent
    }
  }
  
  func rawRecieveData() throws -> [UInt8] {
    var recieveBuffer: [UInt8] = [UInt8](repeating: 0, count: Socket.bufferSize)
    let bytesRead = recv(socketFileDescriptor, &recieveBuffer, Socket.bufferSize, 0)
    guard bytesRead > 0 else {
      switch errno {
      case EAGAIN, EWOULDBLOCK: throw SocketError.nothingToRead
      default: throw SocketError.closed
      }
    }
    Log.verbose("Read \(bytesRead) bytes from \(socketFileDescriptor)", context: "Socket")
    return [UInt8](recieveBuffer[..<Int(bytesRead)])
  }
  
  func peakDataBlock() async throws -> [UInt8] {
    while true {
      do {
        var recieveBuffer: [UInt8] = [UInt8](repeating: 0, count: Socket.bufferSize)
        let bytesRead = recv(socketFileDescriptor, &recieveBuffer, Socket.bufferSize, Int32(MSG_PEEK))
        guard bytesRead > 0 else {
          switch errno {
          case EAGAIN, EWOULDBLOCK: throw SocketError.nothingToRead
          default: throw SocketError.closed
          }
        }
        return [UInt8](recieveBuffer[..<bytesRead])
      } catch SocketError.nothingToRead {
        try await SocketPool.main.waitForChange(on: self)
      }
    }
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
