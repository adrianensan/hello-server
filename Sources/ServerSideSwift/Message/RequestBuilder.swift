import Foundation

import ServerModels

public class HTTPRequestBuilder: Message {
  
  public var clientAddress: String?
  public var method: HTTPMethod = .get
  public var url: String = "/"
  public var host: String?
  public var cookies: [String: String] = [:]
  
  public var request: RawHTTPRequest { RawHTTPRequest(requestBuilder: self) }
}

extension HTTPRequestBuilder: CustomStringConvertible { public var description: String { request.description } }
