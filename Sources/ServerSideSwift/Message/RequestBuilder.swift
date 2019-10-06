import Foundation

public class RequestBuilder: Message, CustomStringConvertible {
  
  public var method: Method = .get
  public var url: String = "/"
  public var host: String?
  public var cookies: [String: String] = [:]
  
  public var finalizedRequest: Request { return Request(method: method,
                                                        url: url,
                                                        host: host,
                                                        cookies: cookies,
                                                        body: body)}
  
  public var description: String { return finalizedRequest.description }
}
