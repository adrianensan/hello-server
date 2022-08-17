import Foundation

import HelloCore

enum ConnectionError: Error {
  case failedToBind
  case failedToConnect
  case failedToResolveHost
}

public class ClientConnection {
  
  private let socket: TCPSocket
  public let clientAddress: NetworkAddress
  
  init(socket: TCPSocket, clientAddress: NetworkAddress) {
    self.socket = socket
    self.clientAddress = clientAddress
  }
  
  func peakRequest() async throws -> HTTPRequest<Data?> {
    let recievedData = try await socket.peakDataBlock()
    return try HTTPRequest<Data?>.parse(data: recievedData.filter{$0 != 13}, allowHeaderOnly: true, from: clientAddress)
  }
  
  func getRequestedHost() async throws -> String {
    let request = try await peakRequest()
    guard let host = request.host else {
      throw SocketError.closed
    }
    return host
  }
  
  func getRequest() async throws -> HTTPRequest<Data?> {
    var recievedData: [UInt8] = []
    var errorLoopCounter = 0
    while true {
      Log.debug("Loop 2", context: "Loop")
      recievedData += try await socket.recieveDataBlock()
      do {
        return try HTTPRequest<Data?>.parse(data: recievedData.filter{$0 != 13}, from: clientAddress)
      } catch HTTPRequestParseError.incompleteRequest {
        continue
      } catch HTTPRequestParseError.invalidRequest {
        guard errorLoopCounter < 3 else { throw SocketError.errorLoop }
        errorLoopCounter += 1
      }
    }
  }
  
  public func send(bytes: [UInt8]) async throws {
    try await socket.sendData(data: bytes)
  }
  
  func send(response: HTTPResponse<Data?>) async throws {
    try await socket.sendData(data: [UInt8](response.data))
  }
  
  public var bytes: AsyncThrowingStream<[UInt8], Error> {
    AsyncThrowingStream { continuation in
      Task {
        while true {
          Log.debug("Loop 3", context: "Loop")
          do {
            continuation.yield(try await socket.recieveDataBlock())
          } catch {
            return continuation.finish(throwing: error)
          }
        }
      }
    }
  }
  
  public var httpRequests: AsyncThrowingStream<HTTPRequest<Data?>, Error> {
    AsyncThrowingStream { continuation in
      Task {
        while true {
          Log.debug("Loop 4", context: "Loop")
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
