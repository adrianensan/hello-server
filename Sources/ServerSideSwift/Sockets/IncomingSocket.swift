import Foundation

class ClientSocket: Socket  {
    
  #if os(Linux)
  static let socketSendFlags: Int32 = Int32(MSG_NOSIGNAL)
  #else
  static let socketSendFlags: Int32 = 0
  #endif
  
  var ipAddress: String
  
  init(socketFD: Int32, clientAddress: String? = nil) {
    ipAddress = clientAddress ?? ""
    super.init(socketFD: socketFD)
    Security.connectionOpened(ipAddress: ipAddress)
  }
  
  deinit {
    Security.connectionClosed(ipAddress: ipAddress)
  }
  
  func peakRawData() -> [UInt8]? {
    var requestBuffer: [UInt8] = [UInt8](repeating: 0, count: Socket.bufferSize)
    while true {
      let bytesRead = recv(socketFileDescriptor, &requestBuffer, Socket.bufferSize, Int32(MSG_PEEK))
      guard bytesRead > 0 else { return nil }
      return [UInt8](requestBuffer[..<bytesRead])
    }
  }
  
  func peakPacket() -> Request? {
    if let data = peakRawData() {
        return Request.parse(data: data.filter{$0 != 13})
    }
    return nil
  }
  
  func acceptRequest() -> Request? {
    var requestBuffer: [UInt8] = [UInt8](repeating: 0, count: Socket.bufferSize)
    var requestLength: Int = 0
    let bytesRead = recv(socketFileDescriptor, &requestBuffer[requestLength], Socket.bufferSize - requestLength, 0)
    guard bytesRead > 0 else { return nil }
    requestLength += bytesRead
    Security.requestRecieved(from: ipAddress)
    return Security.clientHasBadReputation(ipAddress: ipAddress) ? nil : Request.parse(data: requestBuffer[..<requestLength].filter{$0 != 13})
  }
  
  func sendResponse(_ response: Response) {
    let responseBytes: [UInt8] = [UInt8](response.data)
    sendData(data: responseBytes)
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
