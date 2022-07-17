import Foundation

import HelloLog

public struct UDPPacket {
  public var originIPAddress: IPAddress
  public var bytes: [UInt8]
}

public class UDPSocket: Socket {
  
  var port: UInt16
  
  public init(socketFD: Int32, port: UInt16) throws {
    self.port = port
    try super.init(socketFD: socketFD)
  }
  
  public func send(data: [UInt8], to address: IPAddress, on port: UInt16) async throws {
    var bytesToSend = data.count
    var bytesSent = 0
    while bytesToSend > 0 {
      bytesSent += try sendDataPass(data: [UInt8](data[bytesSent...]), to: address, on: port)
      if bytesSent <= 0 {
        throw SocketError.closed
      }
      bytesToSend -= bytesSent
    }
  }
  
  func sendDataPass(data: [UInt8], to address: IPAddress, on port: UInt16) throws -> Int {
    Log.verbose("Sending \(data.count) bytes to \(address.string) on \(socketFileDescriptor)", context: "UDP Socket")
    var toAddr = address.systemAddr(with: port)
    return Int(sendto(socketFileDescriptor, data, data.count, Socket.socketSendFlags, &toAddr, socklen_t(MemoryLayout<sockaddr_in>.size)))
  }
  
  func rawRecieveData() throws -> UDPPacket {
    var recieveBuffer: [UInt8] = [UInt8](repeating: 0, count: Socket.bufferSize)
    var remoteAddr = sockaddr()
    var remoteAddrLength = socklen_t(MemoryLayout<sockaddr>.size)
    let bytesRead = recvfrom(socketFileDescriptor, &recieveBuffer, Socket.bufferSize, 0, &remoteAddr, &remoteAddrLength)
    guard bytesRead > 0 else { throw SocketError.nothingToRead }
    Log.verbose("Read \(bytesRead) bytes from \(socketFileDescriptor)", context: "UDP Socket")
    return UDPPacket(originIPAddress: try IPAddress(from: remoteAddr),
                     bytes: [UInt8](recieveBuffer[..<Int(bytesRead)]))
  }
  
  func recievePacket() async throws -> UDPPacket {
    while true {
      do {
        return try rawRecieveData()
      } catch SocketError.nothingToRead {
        try await SocketPool.main.waitForChange(on: self)
      }
    }
  }
}
