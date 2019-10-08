import Foundation

public class ResponseBuilder: Message, CustomStringConvertible {
    
  public var status: ResponseStatus = .ok
  public var contentType: ContentType = .none
  public var location: String?
  public var lastModifiedDate: Date?
  public var omitBody: Bool = false
  var cookies: [Cookie] = []
  var customeHeaders: [String] = []

  weak private var socket: ClientSocket?
  
  public var response: Response { Response(responseBuilder: self) }
  
  init(clientSocket: ClientSocket? = nil) {
    socket = clientSocket
    super.init()
    if clientSocket is ClientSSLSocket { addCustomHeader(Header.hstsPrefix) }
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
    guard let socket = socket else {
      print("Attempted to complete a response after it was already sent, don't do this, nothing happens")
      return
    }
    socket.sendResponse(response)
    self.socket = nil
  }
  
  public var description: String { response.description }
}
