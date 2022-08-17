import Foundation

import HelloCore

public class HTTPRequestBuilder: Message {
  
  public var clientAddress: NetworkAddress
  public var method: HTTPMethod = .get
  public var url: String = "/"
  public var headers: [String: String] = [:]
  public var cookies: [String: String] = [:]
  
  public init(clientAddress: NetworkAddress) {
    self.clientAddress = clientAddress
  }
}
