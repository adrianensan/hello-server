import Foundation
import OpenSSL

import HelloAPI
import ServerModels
import OFConvenience

let keyword = "?include:"

public enum AccessControl {
  case acceptAll(blocklist: [String])
  case blockAll(allowlist: [String])
  
  func shouldAllowAccessTo(ipAddress: String) -> Bool {
    switch self {
    case .acceptAll(let blocklist): return !blocklist.contains(ipAddress)
    case .blockAll(let allowlist): return allowlist.contains(ipAddress)
    }
  }
}

public protocol ServerEndpoint {
  
  associatedtype RequestBodyType: Codable = Data?
  
  var method: HTTPMethod { get }
  var url: String { get }
  var handler: (any HTTPRequestConformable<RequestBodyType>) async throws -> HTTPResponse { get }
}


//public struct APIServerEndpoint<EndPoint: APIEndpoint>: ServerEndpoint {
//  public var method: HTTPMethod
//  public var url: String
//  public var handler: (RawHTTPRequest) async throws -> HTTPResponse
//
//  public init(_ method: HTTPMethod, _ url: String, _ handler: @escaping (HTTPRequest<EndPoint.RequestBodyType>) async throws -> HTTPResponse) {
//    self.method = method
//    self.url = url
//    self.handler = handler
//  }
//
//  public init(method: HTTPMethod, url: String, handler: @escaping (RawHTTPRequest) async throws -> HTTPResponse) {
//    self.method = method
//    self.url = url
//    self.handler = handler
//  }
//}

public class APIHTTPEndpoint<Endpoint: APIEndpoint>: HTTPEndpoint {
  
  public init(_ apiEndpoint: Endpoint.Type, handler: @escaping (HTTPRequest<Endpoint.RequestBodyType>) async throws -> HTTPResponse) {
    super.init(method: Endpoint.method, url: Endpoint.path) { httpRequest in
      if let data = httpRequest.body {
        switch Endpoint.RequestBodyType.self {
        case is Data.Type, is Data?.Type:
          guard let body = httpRequest.body as? Endpoint.RequestBodyType else {
            return .init(status: .badRequest)
          }
          return try await handler(HTTPRequest(copying: httpRequest, body: body))
        case is String.Type, is String?.Type:
          guard let string = String(data: data, encoding: .utf8) as? Endpoint.RequestBodyType else {
            return .init(status: .badRequest)
          }
          return try await handler(HTTPRequest(copying: httpRequest, body: string))
        default:
          guard let decoded = try? Endpoint.RequestBodyType.decode(from: data) else {
            return .init(status: .badRequest)
          }
          return try await handler(HTTPRequest(copying: httpRequest, body: decoded))
        }
      } else {
        guard let body = httpRequest.body as? Endpoint.RequestBodyType else {
          return .init(status: .badRequest)
        }
        return try await handler(HTTPRequest(copying: httpRequest, body: body))
      }
    }
  }
}

public class HTTPEndpoint {
  
  public var method: HTTPMethod
  public var url: String
  public var handler: (HTTPRequest<Data?>) async throws -> HTTPResponse
  
  public init(_ method: HTTPMethod, _ url: String, _ handler: @escaping (HTTPRequest<Data?>) async throws -> HTTPResponse) {
    self.method = method
    self.url = url
    self.handler = handler
  }
  
  public init(method: HTTPMethod, url: String, handler: @escaping (HTTPRequest<Data?>) async throws -> HTTPResponse) {
    self.method = method
    self.url = url
    self.handler = handler
  }
}

public struct HTTPRedirect {
  public var host: String
  public var sslFiles: SSLFiles?
  
  public init(from host: String, with sslFiles: SSLFiles? = nil) {
    self.host = host
    self.sslFiles = sslFiles
  }
}

public struct HTTPError: Error {
  public var ccde: HTTPResponseStatus
  
  public init(ccde: HTTPResponseStatus) {
    self.ccde = ccde
  }
}

public typealias URLAccess = (url: String, accessControl: AccessControl, responseStatus: HTTPResponseStatus)
 
public protocol Server: Actor {
  var port: UInt16 { get }
  var host: String { get }
  var name: String { get }
  var type: SocketType { get }
  
  var accessControl: AccessControl { get }
  var urlAccessControl: [URLAccess] { get }
}

public protocol TCPServer: Server {
  func handleConnection(connection: ClientConnection) async throws
}

public protocol UDPServer: Server {
  func socketUpdated(to socket: UDPSocket)
  func handle(data: [UInt8], from: IPAddress) async throws
}

public extension UDPServer {
  var type: SocketType { .udp }
}

public extension Server {
  var accessControl: AccessControl { .acceptAll(blocklist: []) }
  var urlAccessControl: [URLAccess] { [] }
  
  func start() async throws {
    try await Router.add(server: self)
  }
  
  func stop() async throws {
    try await Router.remove(server: self)
  }
}
