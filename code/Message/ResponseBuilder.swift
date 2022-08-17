import Foundation

import HelloCore

public class ResponseBuilder: Message {
    
  public var status: HTTPResponseStatus = .ok
  public var contentType: ContentType = .none
  public var location: String?
  public var cache: Cache?
  public var lastModifiedDate: Date?
  public var omitBody: Bool = false
  var cookies: [Cookie] = []
  var customeHeaders: [String] = []
  
  override public init() {
    super.init()
  }
  
  public func addCookie(_ cookie: Cookie) {
    cookies.append(cookie)
  }
  
  public func addCustomHeader(_ line: String) {
    customeHeaders.append(line.filterNewlines)
  }

}
