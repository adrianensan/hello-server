import Foundation

public class RequestBuilder: Message {
  
  public var method: Method = .get
  public var url: String = "/"
  public var host: String?
  public var cookies: [String: String] = [:]
  
  public var request: Request { Request(requestBuilder: self) }
}

extension RequestBuilder: CustomStringConvertible { public var description: String { request.description } }
