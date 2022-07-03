import Foundation
import OpenSSL

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

public struct HTTPEndpoint {
  public var method: HTTPMethod
  public var url: String
  public var handler: (HTTPRequest) async -> HTTPResponse
  
  public init(_ method: HTTPMethod, _ url: String, _ handler: @escaping (HTTPRequest) async -> HTTPResponse) {
    self.method = method
    self.url = url
    self.handler = handler
  }
  
  public init(method: HTTPMethod, url: String, handler: @escaping (HTTPRequest) async -> HTTPResponse) {
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

typealias ServerEndpoint = (method: HTTPMethod, url: String, handler: (_ request: HTTPRequest) async -> HTTPResponse)
public typealias URLAccess = (url: String, accessControl: AccessControl, responseStatus: HTTPResponseStatus)

public protocol Server: AnyObject {
  var port: UInt16 { get }
  var host: String { get }
  var name: String { get }
  
  var accessControl: AccessControl { get }
  var urlAccessControl: [URLAccess] { get }
  
  func handleConnection(connection: ClientConnection) async throws
}

public extension Server {
  var accessControl: AccessControl { .acceptAll(blocklist: []) }
  var urlAccessControl: [URLAccess] { [] }
  
  func start() {
    Router.add(server: self)
  }
}
