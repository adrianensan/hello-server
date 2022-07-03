import Foundation

public class ResponseBuilder: Message {
    
  public var status: HTTPResponseStatus = .ok
  public var contentType: ContentType = .none
  public var location: String?
  public var cache: Cache?
  public var lastModifiedDate: Date?
  public var omitBody: Bool = false
  var cookies: [Cookie] = []
  var customeHeaders: [String] = []
  
  public var response: HTTPResponse { HTTPResponse(responseBuilder: self) }
  
  override public init() {
    super.init()
  }
  
  public func addCookie(_ cookie: Cookie) {
    cookies.append(cookie)
  }
  
  public func addCustomHeader(_ line: String) {
    customeHeaders.append(line.filterNewlines)
  }
  
  public func setBodyJSON<T: Encodable>(object: T, append: Bool = false) {
    if let json = try? JSONEncoder().encode(object) {
      if append { body += json }
      else { body = json }
    }
  }
}

extension ResponseBuilder: CustomStringConvertible { public var description: String { response.description } }
