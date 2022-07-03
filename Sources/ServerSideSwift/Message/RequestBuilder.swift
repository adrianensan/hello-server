import Foundation

public class HTTPRequestBuilder: Message {
  
  public var clientAddress: String?
  public var method: HTTPMethod = .get
  public var url: String = "/"
  public var host: String?
  public var cookies: [String: String] = [:]
  
  public var request: HTTPRequest { HTTPRequest(requestBuilder: self) }
}

extension HTTPRequestBuilder: CustomStringConvertible { public var description: String { request.description } }
