import Foundation
import OpenSSL

public class ClientConnection {
  
  private let socket: Socket
  let clientAddress: String
  private var peakedRequest: HTTPRequest?
  
  init(socket: Socket, clientAddress: String) {
    self.socket = socket
    self.clientAddress = clientAddress
  }
  
  func getRequestedHost() async throws -> String {
    let request = try await getRequest()
    peakedRequest = request
    guard let host = request.host else {
      throw SocketError.closed
    }
    return host
  }
  
  func getRequest() async throws -> HTTPRequest {
    if let request = peakedRequest {
      peakedRequest = nil
      return request
    }
    
    var recievedData: [UInt8] = []
    while true {
      recievedData += try await socket.recieveDataBlock()
      if var request = HTTPRequest.parse(data: recievedData.filter{$0 != 13}) {
        request.clientAddress = clientAddress
        return request
      }
    }
  }
  
  func send(response: HTTPResponse) {
    socket.sendData(data: [UInt8](response.data))
  }
  
  var httpRequests: AsyncThrowingStream<HTTPRequest, Error> {
    AsyncThrowingStream { continuation in
      Task {
        while true {
          do {
            continuation.yield(try await getRequest())
          } catch {
            return continuation.finish(throwing: error)
          }
        }
      }
    }
  }
}
