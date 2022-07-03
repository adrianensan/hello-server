import Foundation

class ClientSocket: Socket {
  
  var ipAddress: String
  
  init(socketFD: Int32, clientAddress: String? = nil) {
    ipAddress = clientAddress ?? ""
    super.init(socketFD: socketFD)
    Security.connectionOpened(ipAddress: ipAddress)
  }
  
  deinit {
    Security.connectionClosed(ipAddress: ipAddress)
  }
  
  func sendResponse(_ response: HTTPResponse) {
    let responseBytes: [UInt8] = [UInt8](response.data)
    sendData(data: responseBytes)
  }
}
