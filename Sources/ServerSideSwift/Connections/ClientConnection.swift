import Foundation
import OpenSSL

class ClientConnection {
  
  private let socket: Socket
  let clientAddress: String
  private var peakedRequest: Request?
  
  init(socket: Socket, clientAddress: String) {
    self.socket = socket
    self.clientAddress = clientAddress
  }
  
  func getRequestedHost() -> String? {
    peakedRequest = socket.recieveRequest()
    return peakedRequest?.host
  }
  
  func getRequest() -> Request? {
    if let request = peakedRequest {
      peakedRequest = nil
      return request
    }
    return socket.recieveRequest()
  }
  
  func send(response: Response) {
    socket.sendData(data: [UInt8](response.data))
  }
  
}
