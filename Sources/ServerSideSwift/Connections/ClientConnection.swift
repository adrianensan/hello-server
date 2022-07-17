import Foundation

import ServerModels

enum ConnectionError: Error {
  case failedToBind
  case failedToConnect
  case failedToResolveHost
}

public class ClientConnection {
  
  private let socket: TCPSocket
  public let clientAddress: String
  
  init(socket: TCPSocket, clientAddress: String) {
    self.socket = socket
    self.clientAddress = clientAddress
  }
  
  func peakRequest() async throws -> RawHTTPRequest {
    var recievedData: [UInt8] = []
    while true {
      recievedData += try await socket.peakDataBlock()
      if var request = RawHTTPRequest.parse(data: recievedData.filter{$0 != 13}) {
        request.clientAddress = clientAddress
        return request
      }
    }
  }
  
  func getRequestedHost() async throws -> String {
    let request = try await peakRequest()
    guard let host = request.host else {
      throw SocketError.closed
    }
    return host
  }
  
  func getRequest() async throws -> RawHTTPRequest {
    var recievedData: [UInt8] = []
    while true {
      recievedData += try await socket.recieveDataBlock()
      if var request = RawHTTPRequest.parse(data: recievedData.filter{$0 != 13}) {
        request.clientAddress = clientAddress
        return request
      }
    }
  }
  
  public func send(bytes: [UInt8]) async throws {
    try await socket.sendData(data: bytes)
  }
  
  func send(response: HTTPResponse) async throws {
    try await socket.sendData(data: [UInt8](response.data))
  }
  
  public var bytes: AsyncThrowingStream<[UInt8], Error> {
    AsyncThrowingStream { continuation in
      Task {
        while true {
          do {
            continuation.yield(try await socket.recieveDataBlock())
          } catch {
            return continuation.finish(throwing: error)
          }
        }
      }
    }
  }
  
  public var httpRequests: AsyncThrowingStream<RawHTTPRequest, Error> {
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
