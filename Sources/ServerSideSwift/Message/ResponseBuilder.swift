import Foundation

public class ResponseBuilder: Message {
    
  public var status: ResponseStatus = .ok
  public var contentType: ContentType = .none
  public var location: String?
  public var lastModifiedDate: Date?
  public var omitBody: Bool = false
  var cookies: [Cookie] = []
  var customeHeaders: [String] = []

  weak private var connection: ClientConnection?
  
  public var response: Response { Response(responseBuilder: self) }
  
  init(clientConnection: ClientConnection? = nil) {
    connection = clientConnection
    super.init()
    if connection is SSLClientConnection { addCustomHeader(Header.hstsPrefix) }
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
  
  public func complete() {
    guard let connection = connection else {
      print("Attempted to complete a response after it was already sent, don't do this, nothing happens")
      return
    }
    connection.send(response: response)
    self.connection = nil
  }
}

extension ResponseBuilder: CustomStringConvertible { public var description: String { response.description } }
