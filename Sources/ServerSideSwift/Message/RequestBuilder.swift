import Foundation

public class RequestBuilder: Message, CustomStringConvertible {
  
  public var method: Method = .get
  public var url: String = "/"
  public var host: String?
  public var cookies: [String: String] = [:]
  
  weak private var socket: OutgoingSocket?
  
  public var finalizedRequest: Request { return Request(method: method,
                                                        url: url,
                                                        host: host,
                                                        cookies: cookies,
                                                        body: body)}
  
  public var description: String { return finalizedRequest.description }
  
  override init() {
    super.init()
  }
  
  public init(to socket: OutgoingSocket) {
    self.socket = socket
    super.init()
  }
  
  public func send(responseHandler: @escaping (Response) -> Void) {
    guard let socket = socket else {
      print("Attempted to complete a request after it was already sent, don't do this, nothing happens")
      return
    }
    if host == nil { host = socket.host }
    socket.sendRequest(finalizedRequest)
    if let response = socket.getResponse() { responseHandler(response) }
    else { print("error") }
    self.socket = nil
  }
}
