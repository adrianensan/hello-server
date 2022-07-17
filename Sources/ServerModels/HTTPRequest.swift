import Foundation

public struct HTTPRequest<Body: Codable>: HTTPRequestConformable {
  
  public var clientAddress: String
  
  public var method: HTTPMethod
  
  public var url: String
  
  public var host: String?
  
  public var cookies: [String : String]
  
  public var body: Body
  
  public init(clientAddress: String, method: HTTPMethod, url: String, host: String? = nil, cookies: [String : String], body: Body) {
    self.clientAddress = clientAddress
    self.method = method
    self.url = url
    self.host = host
    self.cookies = cookies
    self.body = body
  }
  
  public init(copying otherRequest: HTTPRequest<some Codable>, body: Body) {
    self.init(clientAddress: otherRequest.clientAddress,
              method: otherRequest.method,
              url: otherRequest.url,
              host: otherRequest.host,
              cookies: otherRequest.cookies,
              body: body)
  }
}

public protocol HTTPRequestConformable<RequestBodyType> {
  
  associatedtype RequestBodyType: Codable = Data?
  
  var clientAddress: String { get }
  var httpVersion: HTTPVersion { get }
  var method: HTTPMethod { get }
  var url: String { get }
  var host: String? { get }
  var cookies: [String: String] { get }
  var body: RequestBodyType { get }
}


public extension HTTPRequestConformable {
  var httpVersion: HTTPVersion { .http1_1 }
  var body: Data? { nil }
}
